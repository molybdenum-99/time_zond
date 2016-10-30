require_relative 'rule'

module TimeZond
  class Period
    attr_reader :from, :to, :offset, :format, :rules

    def initialize(from: nil, to:, offset:, format:, rules: [])
      @from = from
      @to = to
      @offset = offset
      @format = format
      @rules = rules
    end

    def local(*arg)
      local_by_rules(*arg) || @offset.local(*arg)
    end

    def convert(tm)
      convert_by_rules(tm) || @offset.convert(tm)
    end

    def now
      convert(Time.now)
    end

    def inspect
      '#<%s %s-%s %s>' %
        [
          self.class.name,
          @from ? @from.strftime('%Y/%m/%d') : '...',
          @to.strftime('%Y/%m/%d'),
          [offsets.min, offsets.max].uniq.map(&:to_s).join('-')
        ]
    end

    def ==(other)
      other.is_a?(Period) && from == other.from && to == other.to && offset == other.offset &&
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
        .sort_by { |r, on| on }
        .map(&:first).last.offset.convert(tm)
    end
  end
end
