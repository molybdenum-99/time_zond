module TimeZond
  module Util
    class DayPattern < Struct
      class << self
        def parse(str)
          case str
          when /^\d+$/
            Day.new(day: str)
          when /^last(\S+)$/
            LastWeekday.new(wday: Regexp.last_match[1])
          when /^(\S+)>=(\d+)$/
            WeekdayAfter.new(wday: Regexp.last_match[1], after: Regexp.last_match[2])
          else
            fail ArgumentError, "Unparseable day pattern: #{str.inspect}"
          end
        end
      end

      class Day < self
        attribute :day, &:to_i

        def call(year, month)
          Date.new(year, month, day)
        end
      end

      class LastWeekday < self
        attribute(:wday) { |d| Date::ABBR_DAYNAMES.index(d) }

        def call(year, month)
          month_days(year, month).select { |d| d.wday ==  wday }.last
        end
      end

      class WeekdayAfter < self
        attribute(:wday) { |d| Date::ABBR_DAYNAMES.index(d) }
        attribute(:after, &:to_i)

        def call(year, month)
          month_days(year, month).detect { |d| d.wday ==  wday && d.day >= after }
        end
      end

      private

      def month_days(year, month)
        # FIXME: TimeMath should do it dry-er, somehow!
        TimeMath.day.sequence(Date.new(year, month)...TimeMath.month.next(Date.new(year, month)))
        # One of ideas: TimeMath.month.period(year, month).to_sequence(:day)
      end
    end
  end
end
