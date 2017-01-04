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
        attributes.keys.count < array.count and
          fail(ArgumentError, "Too much attributes for #{self}: #{array.count} of #{attributes.keys.count}")
        new(attributes.keys.zip(array).reject { |k, v| !v }.to_h)
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
        to_h.reject { |k, v| !v }.map { |k, v| "#{k}=#{v}"}.join(' ') +
        '>'
    end

    alias_method :to_s, :inspect
  end
end
