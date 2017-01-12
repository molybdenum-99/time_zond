require 'ostruct'

module TimeZond
  class ZicFile::ParseContext
    class CommentPart < OpenStruct
    end

    class CodeObject < OpenStruct
      def initialize(**)
        super
        self.comments ||= [CommentPart.new]
      end

      def push_comment(line)
        if current_comment.text.to_s.empty?
          current_comment.text = line
        elsif line.empty?
          current_comment.text << "\n\n"
        elsif current_comment.text.end_with?('.') || # definitely should be next line
              line.start_with?('  ')
          current_comment.text << "\n#{line}"
        else
          current_comment.text << " #{line}"
        end
      end

      def comment_part(**attrs)
        comments << CommentPart.new(**attrs)
      end

      def current_comment
        comments.last
      end
    end

    class File < CodeObject
    end

    class Section < CodeObject
    end

    class Comment < CodeObject
    end

    class Zone < CodeObject
      def initialize(**)
        super
        self.periods ||= []
      end
    end

    class Period < CodeObject
    end

    class Rule < CodeObject
    end

    attr_reader :sections, :zones, :rules
    attr_reader :current_object, :current_zone

    def initialize(filename)
      @current_object = @file = File.new(title: filename)

      @sections = []
      @zones = []
      @rules = []
    end

    def section(title)
      sections << Section.new(title: title)
      @current_object = sections.last
      @current_zone = nil
    end

    def comment(line)
      case line
      when /^Zone\t/
        @current_object = Comment.new(scope: :zone)
      when /^Rule\t/
        @current_object = Comment.new(scope: :rule)
      when /^\#{5,}/
        @current_object = @file
      when /\AFrom ([^\n(:]+) \((\d{4}-\d{2}-\d{2})\)(?:,|:|$)(.*)$/
        # TODO: ??? # From Hannu Strang (1994-09-25 06:03:37 UTC):
        @current_object.comment_part(author: $1, date: $2, text: $3.strip)
      else
        @current_object or fail(RuntimeError, "No current object to push comment to")
        @current_object.push_comment(line)
      end
    end

    def zone(data, comment: '')
      zones << Zone.new(name: data.shift, section: sections.last&.title, comments: fetch_comment(:zone) || fetch_comment(:period))
      @current_zone = zones.last
      @current_zone.periods << Period.new(data: data, comment: comment)
      @current_object = Comment.new(scope: :period)
    end

    def period(data, comment: '')
      comments = (fetch_comment(:period) || [])
        .tap { |cs| cs << CommentPart.new(text: comment) }
      @current_zone.periods << Period.new(data: data, comments: comments)
    end

    def rule(data, comment: '')
      comments = (fetch_comment(:rule) || [])
        .tap { |cs| cs << CommentPart.new(text: comment) }

      rules << Rule.new(data: data, section: sections.last, comments: comments)
      @current_object = Comment.new(scope: :rule)
    end

    private

    def fetch_comment(scope)
      if @current_object.is_a?(Comment) && @current_object.scope == scope
        # Once fetched, it is gone
        @current_object.comments.tap { @current_object = Comment.new(scope: @current_object.scope) }
      end
    end
  end
end
