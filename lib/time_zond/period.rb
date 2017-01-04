require_relative 'rule'

module TimeZond
  class Period < Struct
    def self.parse(line, file)
      new(file, attributes.keys.zip(line).reject { |k, v| !v }.to_h)
    end

    attribute :gmt_off, TZOffset.method(:parse)
    attribute :rules, ->(v) {
      case v
      when '-'
        TZOffset.zero
      when /^[+-]?\d+(:\d+(:\d+)?)?$/
        TZOffset.parse(v)
      else
        v
      end
    }

    attribute :format
    attribute :until_year, &:to_i
    attribute :until_month, &Date::ABBR_MONTHNAMES.method(:index)
    attribute :until_day, &:to_i
    attribute :until_time, &Util::TimePattern.method(:parse)

    attr_reader :rule_set, :until

    def initialize(zic_file, **attrs)
      super(**attrs)
      init_until
      @zic_file = zic_file
      @rule_set = zic_file.rules(@rules) if @rules.is_a?(String)
    end

    def matches?(tm)
      materialize_until(tm.year) <= tm
    end

    def local(*components)
      if rules.is_a?(String)
        local_by_rules(*components) || gmt_off.local(*components)
      else
        (gmt_off + rules).local(*components)
      end
    end

    def convert(tm)
      gmt_off.convert(tm)
    end

    private

    FAR_FUTURE = Time.now + 1000 * 365 * 24 * 3600

    def init_until
      if until_year
        @until_month ||= 1
        @until_day ||= 1
        @until_time ||= Util::TimePattern.parse('0:00s')
        @until = until_time.on(Date.new(until_year, until_month, until_day), gmt_off)
      else
        @until = FAR_FUTURE
      end
    end

    def local_by_rules(*components)
      rule_set
        .map { |rule| [rule.activated_at(components.first, gmt_off), (gmt_off + rule.save).local(*components)] }
        .reject { |activated, tm| !activated || tm < activated }.max_by(&:first)&.last
    end
  end
end

__END__

    class << self
      def parse(line, file)
        offset, rules_name, format, *until_parts = line

        until_parts << ['Jan'] if until_parts.count == 1 && until_parts.first =~ /^\d{4}$/
        offset = TZOffset.parse(offset)

        case rules_name
        when '-'
          # do nothing
        when /^[+-]?\d+(:\d+?)$/
          offset += TZOffset.parse(rules_name)
        else
          rules = file.rules(rules_name)
        end

        # TODO: check offset of till
        new(offset: offset, rules: rules, format: format, till: until_parts.empty? ? nil : Time.parse(until_parts.join(' ')))
      end
    end

    attr_reader :till, :offset, :format, :rules

    def initialize(till:, offset:, format:, rules: [])
      @till = till
      @offset = offset
      @format = format
      @rules = rules || []
    end

    def match?(tm)
      # TODO: inclusive or exclusive?..
      !till || till <= tm
    end

    def local(*arg)
      (local_by_rules(*arg) || @offset.local(*arg)).tap { |res|
        return nil unless match?(res)
      }
    end

    def convert(tm)
      convert_by_rules(tm) || @offset.convert(tm)
    end

    def now
      convert(Time.now)
    end

    def inspect
      '#<%s until %s %s>' %
        [
          self.class.name,
          @till ? @till.strftime('%Y/%m/%d') : '...',
          [offsets.min, offsets.max].uniq.map(&:to_s).join('-')
        ]
    end

    def ==(other)
      other.is_a?(Period) && till == other.till && offset == other.offset &&
        format == other.format && rules == other.rules
    end

    private

    def offsets
      @rules.empty? ? [@offset] : @rules.map(&:offset).uniq.sort
    end

    def local_by_rules(year, month = 1, day = 1, hour = 0, min = 0)
      @rules.select { |r| r.from_year <= year }
        .map { |r| [r, r.on.year(year), r.offset.local(year, month, day, hour, min)] }
        .reject { |r, on, localized| on > localized }
        .sort_by { |r, on, localized| [r.from_year, on] }
        .map(&:last).last
    end

    def convert_by_rules(tm)
      @rules.select { |r| r.years.cover?(tm.year) }
        .map { |r| [r, r.on.year(tm.year)] }
        .reject { |r, on| on > tm }
        .sort_by(&:last).map(&:first).last.offset.convert(tm)
    end
  end
end
