module TimeZond
  class ZoneGroup
    attr_reader :title

    def initialize(title, zones)
      @title = title
      @zones = zones
    end
  end
end
