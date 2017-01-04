module TimeZond
  module Util
    class TimePattern < Struct
      def self.parse(time)
        from_a(time.scan(/^(\d+):(\d+)([a-z]?)$/).flatten)
      end

      attribute :hour, &:to_i
      attribute :min, &:to_i
      attribute(:locale) { |letter|
        case letter
        when 'u', 'g', 'z'
          :utc
        when 's'
          :standard
        when 'w', ''
          :local
        else
          fail ArgumentError, "Unparseable time locale: #{time.inspect}"
        end
      }

      def on(date, standard, local = nil)
        offset(standard, local).local(date.year, date.month, date.day, hour, min)
      end

      private

      def offset(standard, local)
        case locale
        when :utc
          TZOffset.zero
        when :standard
          standard
        when :local
          local or fail("Can't instantiate local time")
        end
      end
    end
  end
end

__END__
      class << self

        def parse(mon, on, at)
          mon = Date::ABBR_MONTHNAMES.index(mon)
          hour, min, locale = parse_time(at)

          case on
          when /^\d+$/
            Util::TimePattern::Day.new(mon: mon, day: on.to_i, hour: hour, min: min, locale: locale)
          when /^last(\S+)$/
            wday = Date::ABBR_DAYNAMES.index(Regexp.last_match[1])
            Util::TimePattern::LastWeekday.new(mon: mon, wday: wday, hour: hour, min: min, locale: locale)
          when /^(\S+)>=(\d+)$/
            after = Regexp.last_match[2].to_i
            wday = Date::ABBR_DAYNAMES.index(Regexp.last_match[1])
            Util::TimePattern::WeekdayAfter.new(mon: mon, wday: wday, after: after, hour: hour, min: min, locale: locale)
          else
            fail ArgumentError, "Unparseable day pattern: #{day.inspect}"
          end
        end

        private

        def parse_time(time)
          hour, min, letter = time.scan(/^(\d+):(\d+)([a-z]?)$/).flatten
          [hour, min, parse_locale(letter)]
        end

        def parse_locale(letter)
          case letter
          when 'u', 'g', 'z'
            :utc
          when 's'
            :standard
          when 'w', ''
            :local
          else
            fail ArgumentError, "Unparseable time locale: #{time.inspect}"
          end
        end
      end

      attr_reader :mon, :hour, :min, :sec, :locale

      def inspect
        '#<%s %s, %s, %02i:%02i:%02i%s>' %
          [
            'TimeZond::Util::TimePattern', # FIXME?
            Date::ABBR_MONTHNAMES[@mon],
            inspect_day,
            @hour,
            @min,
            @sec,
            @locale
          ]
      end

      def for_year(y)
        @offset.local(y, @mon, calc_day(y), @hour, @min, @sec)
      end

      def ==(other)
        other.class == self.class && other.mon == mon &&
          other.hour == hour && other.min == min && other.sec == sec &&
          other.offset == offset && day_equal?(other)
      end

      private

      def month_days(year)
        TimeMath.month.period(year, @mon).to_sequence(:day).to_a
      end

      class Day < self
        attr_reader :day

        def initialize(mon:, day: , hour: 0, min: 0, sec: 0, locale:)
          @mon = mon
          @day = day
          @hour = hour
          @min = min
          @sec = sec
          @locale = locale
        end

        private

        def day_equal?(other)
          day == other.day
        end

        def calc_day(_)
          @day
        end

        def inspect_day
          @day.to_s
        end
      end

      class LastWeekday < self
        attr_reader :wday

        def initialize(mon:, wday:, hour: 0, min: 0, sec: 0, locale:)
          @mon = mon
          @wday = wday
          @hour = hour
          @min = min
          @sec = sec
          @locale = locale
        end

        private

        def day_equal?(other)
          wday == other.wday
        end

        def calc_day(year)
          month_days(year).select { |d| d.wday ==  @wday }.last.day
        end

        def inspect_day
          "last #{Date::DAYNAMES[@wday]}"
        end
      end

      class WeekdayAfter < self
        attr_reader :wday, :after

        def initialize(mon:, wday:, after:, hour: 0, min: 0, sec: 0, locale:)
          @mon = mon
          @wday = wday
          @after = after
          @hour = hour
          @min = min
          @sec = sec
          @locale = locale
        end

        private

        def day_equal?(other)
          wday == other.wday && after == other.after
        end

        def calc_day(year)
          month_days(year).detect { |d| d.wday ==  @wday && d.day >= @after }.day
        end

        def inspect_day
          "#{Date::DAYNAMES[@wday]} >= #{@after}"
        end
      end
    end

  end
end
