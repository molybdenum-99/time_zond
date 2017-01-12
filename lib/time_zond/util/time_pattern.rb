module TimeZond
  module Util
    class TimePattern < Struct
      PATTERN = /^(\d+):(\d+)(?::(\d+))?([a-z]?)$/

      def self.parse(time)
        time =~ PATTERN or fail ArgumentError, "Unparseable time #{time.inspect}"
        from_a(time.scan(PATTERN).flatten)
      end

      attribute :hour, &:to_i
      attribute :min, &:to_i
      attribute :sec, &:to_i
      attribute(:locale) { |letter|
        case letter
        when 'u', 'g', 'z'
          :utc
        when 's'
          :standard
        when 'w', ''
          :local
        else
          fail ArgumentError, "Unparseable time locale: #{time.inspect}"
        end
      }


      def on(date, standard, local = nil)
        offset(standard, local).local(date.year, date.month, date.day, hour, min, sec)
      end

      def to_s
        '%02i:%02i:%02i' % [hour, min, sec.to_i]
      end

      private

      def offset(standard, local)
        case locale
        when :utc
          TZOffset.zero
        when :standard
          standard
        when :local
          #local or fail("Can't instantiate local time")
          local || standard # FIXME!!!!
        end
      end
    end
  end
end
