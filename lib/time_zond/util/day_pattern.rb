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

      module MonthWeekdays
        def call(year, month)
          Date.new(year, month, select_day(wdays_list(year, month, wday)))
        end

        private

        def wdays_list(year, month, wday)
          first_wday = Date.new(year, month).wday
          (1..days_in_month(month, year)).select { |d| (d - 1 + first_wday) % 7 == wday }
        end

        COMMON_YEAR_DAYS_IN_MONTH = [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

        def days_in_month(month, year)
           return 29 if month == 2 && Date.gregorian_leap?(year)
           COMMON_YEAR_DAYS_IN_MONTH[month]
        end
      end

      class LastWeekday < self
        include MonthWeekdays

        attribute :wday, &Date::ABBR_DAYNAMES.method(:index)

        private

        def select_day(list)
          list.last
        end
      end

      class WeekdayAfter < self
        include MonthWeekdays

        attribute :wday, &Date::ABBR_DAYNAMES.method(:index)
        attribute :after, &:to_i

        private

        def select_day(list)
          list.detect { |d| d >= after }
        end
      end
    end
  end
end
