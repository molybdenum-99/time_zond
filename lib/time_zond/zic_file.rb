module TimeZond
  class ZicFile
    def self.read(path, sections: [])
      new(File.basename(path), File.read(path).split("\n"), sections: sections)
    end

    attr_reader :zone_data, :rule_data

    def initialize(name, lines, comments: false, sections: [])
      @name = name
      @comments = comments

      parse(lines, sections)
    end

    def zone(name)
      @zones.fetch(name) { fail ArgumentError, "Timezone #{name.inspect} not found" }
    end

    def section(title)
      @sections.fetch(title) { fail ArgumentError, "Timezone file section #{title.inspect} not found" }
    end

    def rules(name)
      @rules.fetch(name) { fail ArgumentError, "Timezone rule #{name.inspect} not found" }
    end

    private

    def parse(lines, sections)
      @context = ParseContext.new(@name)

      lines.each_with_index.to_a.map(&:reverse)
        .map { |i, ln| [i, *ln.split('#', 2)] } # .reject { |_i, ln, _c| !@comments && ln.strip.empty? }
        .map { |i, ln, c| [i, ln.to_s.split(/\s+/), c.to_s.sub(/^\ /, '')] }
        .each { |i, ln, c| parse_line(ln, c, i, sections) }

      create_objects

      @context = nil
    end

    def create_objects
      @sections = @context.sections
        .map { |s| Docs::Section.from_a([s.title], comments: s.comments) }
        .map { |s| [s.title, s] }.to_h
      @rules = @context.rules
        .map { |r| Rule.from_a(r.data, comments: r.comments) }.group_by(&:name).to_h
      @zones = @context.zones
        .map { |z| Zone.parse(self, z.name, z.periods.map { |p| [p.data, p.comments] }, z.section, z.comments) }
        .map { |z| [z.name, z] }.to_h
    end

    def parse_line(content, comment, lineno, sections)
      if content.empty?
        if sections.include?(comment)
          @context.section(comment)
        else
          @context.comment(comment)
        end
      else
        parse_content(content, comment, lineno)
      end
    end

    def parse_comment(comment, lineno)
      case comment.sub(/^\# /, '')
      when /^Zone\t/
        @state.comment_context = :zone
      when /^Rule\t/
        @state.comment_context = :rule
      when *@group_names
        @state.comment_context = :group
        @state.comment_groups << CommentGroupData.new(comment.sub(/^\# /, ''))
      else
        @state.push_comment(comment)
      end
    end

    def parse_content(ln, comment, lineno)
      case ln.shift
      when 'Leap'
        # ignoring for now
      when 'Link'
        # ignoring for now
      when 'Rule'
        @context.rule(ln, comment: comment)
      when 'Zone'
        @context.zone(ln, comment: comment)
      when ''
        @context.period(ln, comment: comment)
      else
        fail ArgumentError, "Unparseable line #{lineno}: #{ln}"
      end
    end
  end
end

require_relative 'zic_file/parse_context'
