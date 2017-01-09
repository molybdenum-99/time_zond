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

    def parse_line(content, comment, lineno)
      if content.empty?
        parse_comment(comment, lineno)
      else
        parse_content(content, comment, lineno)
        @state.finalize_comment!
      end
    end

    class State
      attr_reader :rules, :zones

      def initialize
        @rules = []
        @zones = []
        @comment_groups = []
        @comment_context = :global
        @comments = {}
        @current_comment = nil
      end

      def current_zone
        @zones.last
      end

      def current_group
        @comment_groups.last
      end

      def finalize_comment
        @current_comment = nil
      end

      def fetch_comment(type)
        if @current_comment.type == type
          com, @current_comment = @current_comment, nil
          com
        end
      end

      def push_comment(text)
        @current_comment ||= CommentData.new(@comment_context)
        @current_comment << text
        if @comment_context == :group
          @current_group.comments << text
        end
      end

      def comment_context=(contextname)
        if @comment_context != contextname
          @comment_context = contextname
          @current_comment = nil
        end
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
      #case ln.shift
      #when 'Leap'
        ## ignoring for now
      #when 'Link'
        ## ignoring for now
      #when 'Rule'
        #@state.rules << RuleData.new(name: ln.shift, data: ln, comments: [*@state.fetch_comments(:rule), comment]])
      #when 'Zone'
        #@state.zones << ZoneData.new(name: ln.shift, comments_group: @state.current_group, comments: @state.fetch_comments(:zone))
        #@state.current_zone.periods << PeriodData.new(data: ln, comments: [comment])
        #@state.comment_context = :period
      #when ''
        #@state.current_zone.periods << PeriodData.new(data: ln, comments: [*@state.fetch_comments(:period), comment])
      #else
        #fail ArgumentError, "Unparseable line #{lineno}: #{ln}"
      #end
    end
  end
end
