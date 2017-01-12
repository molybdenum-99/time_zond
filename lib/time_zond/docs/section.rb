module TimeZond
  module Docs
    class Section < Struct
      attribute :title

      include Commentable

      def inspect
        if comments.count == 1
          '#<%s(%s): %s>' % [self.class, title, comments.first.short_text]
        else
          '#<%s(%s): %i comments>' % [self.class, title, comments.count]
        end
      end
    end
  end
end
