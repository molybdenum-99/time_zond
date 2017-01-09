require 'ostruct'

module TimeZond
  class ZicFile::ParseContext
    class CodeObject < OpenStruct
      def push_comment(line)
        if self.comment.to_s.empty?
          self.comment = line
        else
          self.comment << "\n#{line}"
        end
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

    def initialize
      @current_object = Comment.new(scope: :global, comment: '')
      @sections = []
      @zones = []
      @rules = []
    end

    def file(title)
      @current_object = @file = File.new(title: title)
    end

    def section(title)
      sections << Section.new(title: title)
      @current_object = sections.last
      @current_zone = nil
    end

    def comment(line)
      case line
      when /^Zone\t/
        @current_object = Comment.new(scope: :zone, comment: '')
      when /^Rule\t/
        @current_object = Comment.new(scope: :rule, comment: '')
      when /^\#{5,}/
        @current_object = @file
      else
        @current_object or fail(RuntimeError, "No current object to push comment to")
        @current_object.push_comment(line)
      end
    end

    def zone(data, comment: '')
      zones << Zone.new(name: data.shift, section: sections.last, comment: fetch_comment(:zone))
      @current_zone = zones.last
      @current_zone.periods << Period.new(data: data, comment: comment)
      @current_object = Comment.new(scope: :period, comment: '')
    end

    def period(data, comment: '')
      comment = [fetch_comment(:period), comment].compact.reject(&:empty?).join("\n")
      @current_zone.periods << Period.new(data: data, comment: comment)
    end

    def rule(data, comment: '')
      comment = [fetch_comment(:rule), comment].compact.reject(&:empty?).join("\n")
      rules << Rule.new(data: data, section: sections.last, comment: comment)
      @current_object = Comment.new(scope: :rule, comment: '')
    end

    private

    def fetch_comment(scope)
      if @current_object.is_a?(Comment) && @current_object.scope == scope
        # Once fetched, it is gone
        @current_object.comment.tap { @current_object = Comment.new(scope: @current_object.scope, comment: '') }
      else
        ''
      end
    end
  end
end
