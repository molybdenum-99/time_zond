module TimeZond
  class ZicFile
    def self.read(path)
      new File.read(path).split("\n")
    end

    attr_reader :zone_data, :rule_data

    def initialize(lines, comments: false, countries: [])
      @zone_data = Hash.new { |h, k| h[k] = [] }
      @rule_data = Hash.new { |h, k| h[k] = [] }
      @comments = []

      parse(lines)
    end

    def zone(name)
      fail ArgumentError, "Timezone #{name} not found" unless @zone_data.key?(name)
      Zone.parse(name, @zone_data[name], self)
    end

    def rules(name)
      fail ArgumentError, "Timezone rule #{name} not found" unless @rule_data.key?(name)
      @rule_data[name].map { |ln| Rule.from_a([name, *ln]) }
    end

    private

    def parse(lines)
      @current_zone = nil

      lines.each_with_index.to_a.map(&:reverse)
        .map { |i, ln| [i, *ln.split('#', 2)] }
        .reject { |_i, ln, _c| !@comments && ln.strip.empty? }
        .map { |i, ln, c| [i, ln.split(/\s+/), c] }
        .each { |ln, i| parse_line(ln, c.to_s, i) }

      @current_zone = nil
    end

    def parse_line(ln, comment, lineno)
      if ln.empty?
      case ln.shift
      when 'Link', 'Leap'
        # ignoring for now
      when 'Rule'
        @rule_data[ln.shift] << ln
      when 'Zone'
        @current_zone = ln.shift
        @zone_data[@current_zone] << ln
      when ''
        @zone_data[@current_zone] << ln
      else
        fail ArgumentError, "Unparseable line #{lineno}: #{ln}"
      end
    end
  end
end
