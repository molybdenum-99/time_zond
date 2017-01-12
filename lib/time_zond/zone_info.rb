module TimeZond
  class ZoneInfo
    def self.read(path = './data')
      new(path)
    end

    ADDITIONAL_SECTIONS = [
      'Britain (United Kingdom) and Ireland (Eire)',
      'Europe',
      'Bosnia and Herzegovina',
      'Denmark, Faroe Islands, and Greenland',
    ].freeze

    def initialize(path)
      @path = File.expand_path(path)
      @version = File.read(File.join(path, 'version')).chomp
      @iso3166 = read_tab(File.join(path, 'iso3166.tab')).map(&:reverse).to_h
      @countries2zones = read_tab(File.join(path, 'zone1970.tab'))
        .flat_map { |codes, _, zone, *| codes.split(',').map { |c| [c, zone] } }.to_h

      @zics = Dir[File.join(path, '*')]
        .select { |f| File.basename(f) =~ /^[a-z]+$/ }
        .reject { |f| %w[version backzone].include?(File.basename(f)) } # TODO: probably, backzone should also be parsed?
        .map { |f| ZicFile.read(f, sections: @iso3166.keys + ADDITIONAL_SECTIONS) }
    end

    def countries
      @iso3166.values.sort
    end

    def country_codes
      @iso3166.keys
    end

    def zone(name)
      @zics.map { |z| z.zone(name) rescue nil }.compact.first
    end

    def inspect
      '#<%s %s (from %s)>' % [self.class, @version, @path]
    end

    private

    def read_tab(path)
      File.read(path).split("\n")
        .reject { |ln| ln.start_with?('#') || ln.strip.empty? }
        .map { |ln| ln.split("\t") }
    end
  end
end
