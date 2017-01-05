require_relative 'rule'

module TimeZond
  class Period < Struct
    def self.parse(line, file)
      new(file, attributes.keys.zip(line).reject { |_, v| !v }.to_h)
    end

    attribute :gmt_off, &TZOffset.method(:parse)
    attribute(:rules) { |rs|
      case rs
      when '-'
        TZOffset.zero
      when /^[+-]?\d+(:\d+(:\d+)?)?$/
        TZOffset.parse(rs)
      else
        rs
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
      @rule_set = zic_file.rules(rules) if rule_set?
    end

    def matches?(tm)
      materialize_until(tm.year) <= tm
    end

    def local(*components)
      if rule_set?
        local_by_rules(*components) || gmt_off.local(*components)
      else
        (gmt_off + rules).local(*components)
      end
    end

    def convert(tm)
      if rule_set?
        convert_by_rules(tm) || gmt_off.convert(tm)
      else
        (gmt_off + rules).convert(tm)
      end
    end

    def offsets
      if rule_set?
        rule_set.map { |r| gmt_off + r.save }
      else
        [gmt_off + rules]
      end
    end

    private

    def rule_set?
      rules.is_a?(String)
    end

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

    def convert_by_rules(tm)
      rule_set
        .reject { |rule| rule.from > tm.year }
        .map { |rule| [rule.activated_at(tm.year, gmt_off), (gmt_off + rule.save).convert(tm)] }
        .reject { |activated, t| !activated || t < activated }.max_by(&:first)&.last
    end

    def local_by_rules(*components)
      rule_set
        .map { |rule|
          [rule.activated_at(components.first, gmt_off), (gmt_off + rule.save).local(*components)]
        }
        .reject { |activated, tm| !activated || tm < activated }.max_by(&:first)&.last
    end
  end
end
