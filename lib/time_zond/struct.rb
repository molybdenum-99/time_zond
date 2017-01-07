module TimeZond
  class Struct
    class << self
      def attribute(name, parser = nil, &block)
        attributes[name] = (parser || block || :to_s).to_proc
        attr_reader name
      end

      def attributes
        @attributes ||= {}
      end

      def from_a(array)
        validate_array_size(array.count)
        new(attributes.keys.zip(array).reject { |_, v| !v }.to_h)
      end

      def inherited(child)
        child.instance_variable_set('@attributes', attributes.dup)
      end

      private

      def validate_array_size(count)
        count <= attributes.keys.count or
          fail ArgumentError, "Too much attributes for #{self}: #{count} of #{attributes.keys.count}"
      end
    end

    def initialize(**strings)
      strings.each do |key, value|
        instance_variable_set("@#{key}", self.class.attributes.fetch(key).call(value))
      end
    end

    def to_h
      self.class.attributes.map { |n, _| [n, instance_variable_get("@#{n}")] }.to_h
    end

    def ==(other)
      other.class == self.class && other.to_h == to_h
    end

    def inspect
      "#<#{self.class.name} " +
        to_h.reject { |_, v| !v }.map { |k, v| "#{k}=#{v}" }.join(' ') +
        '>'
    end

    alias_method :to_s, :inspect
  end
end
