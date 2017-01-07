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
      period_at(tm).convert(tm)
    end

    def period_at(tm)
      periods.detect { |period| period.until > tm }
    end

    def current_period
      period_at(Time.now)
    end

    def current_offset
      current_period.current_offset
    end

    def now
      convert(Time.now)
    end

    def parse(str, now = Time.now)
      defaults = {
        year: now.year,
        month: now.month,
        mday: now.day,
        hour: now.hour,
        min: now.min,
        sec: now.sec,
        offset: current_offset.to_i
      }
      components = defaults.merge(Date._parse(str))
      Time.new(*%i[year month mday hour min sec offset].map(&components.method(:fetch)))
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
