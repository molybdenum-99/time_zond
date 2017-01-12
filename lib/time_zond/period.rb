module TimeZond
  class Period < Struct
    def self.parse(line, comments, file)
      case line[1]
      when '-', /^[+-]?\d+(:\d+(:\d+)?)?$/
        ByOffset.from_a(line, comments: comments)
      else
        ByRules.from_a([line[0], file.rules(line[1]), *line[2..-1]], comments: comments)
      end
    end

    FAR_FUTURE = Time.now + 1000 * 365 * 24 * 3600

    attribute :gmt_off, &TZOffset.method(:parse)
    attribute :rules
    attribute :format
    attribute :until_year, &:to_i
    attribute :until_month, &Date::ABBR_MONTHNAMES.method(:index)
    attribute :until_day, &Util::DayPattern.method(:parse)
    attribute :until_time, &Util::TimePattern.method(:parse)

    include Docs::Commentable

    attr_reader :until

    def initialize(**strings)
      super(**strings)
      init_until
    end

    class ByOffset < self
      # rewrite parsing
      attribute(:rules) { |rs|
        case rs
        when '-'
          TZOffset.zero
        when /^[+-]?\d+(:\d+(:\d+)?)?$/
          TZOffset.parse(rs)
        end
      }

      alias_method :add_offset, :rules

      def local(*components)
        offset.local(*components)
      end

      def convert(tm)
        offset.convert(tm)
      end

      def offsets
        [offset]
      end

      def offset
        gmt_off + add_offset
      end

      def offset_at(_tm)
        offset
      end

      def inspect
        '#<%s(%s) %s%s (%s)%s>' %
          [self.class, format, add_offset.zero? ? '' : add_offset, offset, inspect_until, short_comments]
      end
    end

    class ByRules < self
      # rewrite parsing
      attribute(:rules, &:itself)

      def local(*components)
        local_by_rules(*components) || gmt_off.local(*components)
      end

      def convert(tm)
        convert_by_rules(tm) || gmt_off.convert(tm)
      end

      def offsets
        rules.map { |r| gmt_off + r.save }
      end

      def offset_at(tm)
        r = rule_at(tm)
        r ? gmt_off + r.save : gmt_off
      end

      def inspect
        '#<%s(%s) %s%s (%s)%s>' %
          [self.class, formats.join('/'), rules.first.name, gmt_off, inspect_until, short_comments]
      end

      private

      def formats
        format.split('/').flat_map { |f| rules.map(&:letters).sort.uniq.map { |l| f % l } }.uniq
      end

      def convert_by_rules(tm)
        rules
          .reject { |rule| rule.from > tm.year }
          .map { |rule| [rule.activated_at(tm.year, gmt_off), (gmt_off + rule.save).convert(tm)] }
          .reject { |activated, t| !activated || t < activated }.max_by(&:first)&.last
      end

      def rule_at(tm)
        rules
          .reject { |rule| rule.from > tm.year }
          .map { |rule| [rule.activated_at(tm.year, gmt_off), (gmt_off + rule.save).convert(tm), rule] }
          .reject { |activated, t, _r| !activated || t < activated }.max_by(&:first)&.last
      end

      def local_by_rules(*components)
        rules
          .map { |rule|
            [rule.activated_at(components.first, gmt_off), (gmt_off + rule.save).local(*components)]
          }
          .reject { |activated, tm| !activated || tm < activated }.max_by(&:first)&.last
      end
    end

    def current_offset
      offset_at(Time.now)
    end

    def current?
      @until == FAR_FUTURE
    end

    private

    def inspect_until
      current? ? 'current' : @until.strftime('until %b %d, %Y')
    end

    def init_until
      if until_year
        @until_month ||= 1
        @until_day ||= Util::DayPattern.parse('1')
        @until_time ||= Util::TimePattern.parse('0:00s')
        @until = until_time.on(until_day.call(until_year, until_month), gmt_off)
      else
        @until = FAR_FUTURE
      end
    end
  end
end
