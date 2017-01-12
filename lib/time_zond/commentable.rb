require_relative 'comment'
require_relative 'comments'

module TimeZond
  module Commentable
    def self.included(klass)
      klass.attribute :comments, &Comments.method(:parse)

      klass.define_singleton_method(:from_a) { |array, comments: ''|
        new(attributes.keys.zip(array).reject { |_, v| !v }.to_h.merge(comments: comments))
      }
    end

    private

    def short_comments
      comments.empty? ? '' : " # #{comments.first.short_text}"
    end

    def limit(str, length)
      str.split("\n").first.sub(/^(.{#{length-3}}).*$/, '\1...')
    end
  end
end
