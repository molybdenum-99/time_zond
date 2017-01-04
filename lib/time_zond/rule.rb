require_relative 'util/time_pattern'

module TimeZond
  class Rule < Struct
    attribute(:name)
    attribute(:from, &:to_i)
    attribute(:to){ |y|
      case y
      when 'only'
        nil
      when 'max'
        Float::INFINITY
      when /^\d+$/
        y.to_i
      else
        faile ArugmentError, "Unparseable 'to' year: #{y}"
      end
    }
    attribute(:type) { |t| t == '-' ? nil : t }
    attribute(:in, &Date::ABBR_MONTHNAMES.method(:index))
    attribute(:on, &Util::DayPattern.method(:parse))
    attribute(:at, &Util::TimePattern.method(:parse))
    attribute(:save, &TZOffset.method(:parse))
    attribute(:letters) { |l| l == '-' ? nil : l }

    def initialize(*)
      super
      @to ||= @from
    end

    def activated_at(year, standard)
      return nil unless (@from..@to).cover?(year)
      date = on.call(year, @in)
      at.on(date, standard, standard + save)
    end

    def matches?(y, m = 1, d = 1, h = 0, min = 0, s = 0)
      if y.is_a?(Time)
        matches_time?(y)
      else
        matches_components?(y, m, d, h, min, s)
      end
    end

    private

    #def matches_time?(tm)
    #end

    #def matches_components?(y, m, d, h, min, s)
      #return true if m < in
      #return true if d < on.for(y, m)
      #!!!!!!! y, m, d, h, min, s <
    #end
  end
end

__END__

    attr_reader :name, :from_year, :to_year, :type, :on, :save, :letters

    def initialize(name:, from_year:, to_year:, type:, on:, save:, letters:)
      @name = name
      @from_year = from_year
      @to_year = to_year
      @type = type
      @on = on
      @save = save
      @letters = letters
    end

    def years
      from_year..to_year
    end
  end
end
