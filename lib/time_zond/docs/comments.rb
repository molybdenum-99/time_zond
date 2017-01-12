module TimeZond
  module Docs
    class Comments < Array
      def self.parse(comment_parts)
        new comment_parts.map(&:to_h).map(&Comment.method(:new)).reject { |c| c.text.empty? }
      end

      def short_inspect
        raise NotImplementedError
      end

      def to_s
        join("\n")
      end
    end
  end
end
