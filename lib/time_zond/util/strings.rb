module TimeZond
  module Util
    module Strings
      module_function

      def limit(str, length)
        str.split("\n").first.to_s.sub(/^(.{#{length-3}}).*$/, '\1...')
      end
    end
  end
end
