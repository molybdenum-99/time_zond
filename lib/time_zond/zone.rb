module TimeZond
  class Zone
    attr_reader :name, :periods

    def initialize(name, periods)
      @name = name
      @periods = periods
    end
  end
end
