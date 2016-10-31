module TimeZond
  class Zone
    def self.all
      @all ||= {}
    end

    attr_reader :name, :periods

    def initialize(name, periods)
      @name = name
      @periods = periods
    end
  end
end
