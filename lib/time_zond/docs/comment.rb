module TimeZond
  module Docs
    class Comment < Struct
      attribute :author
      attribute :date, &Date.method(:parse)
      attribute :text

      def initialize(**)
        super
        @text ||= ''
      end

      def inspect
        if authored?
          '#<%s(%s, %s): %s>' % [self.class, author, date.strftime('%Y-%m-%d'), short_text]
        else
          '#<%s: %s>' % [self.class, short_text]
        end
      end

      def to_s
        if authored?
          "From #{author} (#{date.strftime('%Y-%m-%d')}):\n#{text}"
        else
          text
        end
      end

      def authored?
        author && date
      end

      def short_text
        Util::Strings.limit(text, 30)
      end
    end
  end
end
