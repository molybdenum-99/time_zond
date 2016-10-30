module TimeZond
  module Util
    class TimePattern
      def self.parse(mon, day, time, standard: TZOffset.zero, local: TZOffset.zero)
        mon = Date::ABBR_MONTHNAMES.index(mon)
        hour, min = time.split(':').map(&:to_i)

        offset = case time.scan(/[a-z]?$/).first
        when 'u', 'g', 'z'
          TZOffset.zero
        when 's'
          standard
        when 'w', ''
          local
        else
          fail ArgumentError, "Unparseable time locale: #{time.inspect}"
        end

        case day
        when /^\d+$/
          Day.new(mon: mon, day: day.to_i, hour: hour, min: min, offset: offset)
        when /^last(\S+)$/
          wday = Date::ABBR_DAYNAMES.index(Regexp.last_match[1])
          LastWeekday.new(mon: mon, wday: wday, hour: hour, min: min, offset: offset)
        when /^(\S+)>=(\d+)$/
          after = Regexp.last_match[2].to_i
          wday = Date::ABBR_DAYNAMES.index(Regexp.last_match[1])
          WeekdayAfter.new(mon: mon, wday: wday, after: after, hour: hour, min: min, offset: offset)
        else
          fail ArgumentError, "Unparseable day pattern: #{day.inspect}"
        end
      end

      attr_reader :mon, :hour, :min, :sec, :offset

      def inspect
        '#<%s %s, %s, %02i:%02i:%02i%s>' %
          [
            'TimeZond::Util::TimePattern', # FIXME?
            Date::ABBR_MONTHNAMES[@mon],
            inspect_day,
            @hour,
            @min,
            @sec,
            @offset
          ]
      end

      def year(y)
        @offset.local(y, @mon, calc_day(y), @hour, @min, @sec)
      end

      def ==(other)
        other.class == self.class && other.mon == mon &&
          other.hour == hour && other.min == min && other.sec == sec &&
          other.offset == offset && day_equal?(other)
      end

      private

      def month_days
        TimeMath.month.period(year, @mon).to_sequence(:day).to_a
      end

      class Day < self
        attr_reader :day

        def initialize(mon:, day: , hour: 0, min: 0, sec: 0, offset: TZOffset.zero)
          @mon = mon
          @day = day
          @hour = hour
          @min = min
          @sec = sec
          @offset = offset
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

        def initialize(mon:, wday:, hour: 0, min: 0, sec: 0, offset: TZOffset.zero)
          @mon = mon
          @wday = wday
          @hour = hour
          @min = min
          @sec = sec
          @offset = offset
        end

        private

        def day_equal?(other)
          wday == other.wday
        end

        def calc_day(year)
          month_days.select { |d| d.wday ==  @wday }.last.day
        end

        def inspect_day
          "last #{Date::DAYNAMES[@wday]}"
        end
      end

      class WeekdayAfter < self
        attr_reader :wday, :after

        def initialize(mon:, wday:, after:, hour: 0, min: 0, sec: 0, offset: TZOffset.zero)
          @mon = mon
          @wday = wday
          @after = after
          @hour = hour
          @min = min
          @sec = sec
          @offset = offset
        end

        private

        def day_equal?(other)
          wday == other.wday && after == other.after
        end

        def calc_day(year)
          month_days.detect { |d| d.wday ==  @wday && d.day >= @after }.day
        end

        def inspect_day
          "#{Date::DAYNAMES[@wday]} >= #{@after}"
        end
      end
    end

  end
end
