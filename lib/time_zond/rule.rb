require_relative 'util/time_pattern'

module TimeZond
  class Rule < Struct
    attribute(:name)
    attribute(:from, &:to_i)
    attribute(:to) { |y|
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
    attribute(:letters) { |l| l == '-' ? '' : l }

    include Docs::Commentable

    def initialize(*)
      super
      @to ||= @from
    end

    def activated_at(year, standard)
      return nil if @from > year

      # If rule is (2015, 2016), and we are asking about 2017, the last activation was in
      #   2016 -- but the rule can still be active, if it is the last one.
      year = @to if @to < year
      date = on.call(year, @in)
      at.on(date, standard, standard + save)
    end

    def inspect
      '#<%s(%s) %s, since %s, %s at %s: %s%s>' %
        [self.class, name, inspect_years, Date::ABBR_MONTHNAMES[self.in], on, at, save, short_comments]
    end

    private

    def inspect_years
      return from if to == from
      "#{from}-#{to.to_f.infinite? ? '...' : to}"
    end
  end
end
