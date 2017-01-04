module TimeZond
  class Zone
    def self.all
      @all ||= {}
    end

    def self.parse(name, periods, file)
      new(name, periods.map { |ln| Period.parse(ln, file) })
    end

    attr_reader :name, :periods

    def initialize(name, periods)
      @name = name
      @periods = periods.sort_by(&:until)
    end

    def local(*components)
      periods.each do |period|
        period.local(*components).tap { |tm| return tm if tm < period.until }
      end
      nil
    end

    def convert(tm)
      periods.detect { |period| period.until > tm }.convert(tm)
    end

    def period_for(tm)
      periods.detect { |p| p.match?(tm) }
    end

    def now
      convert(Time.now)
    end

    def to_s
      name
    end

    def inspect
      '#<%s %s (%i periods, %s - %s)>' %
        [self.class, name, periods.count, *periods.flat_map(&:offsets).minmax]
    end
  end
end
