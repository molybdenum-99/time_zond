require_relative 'util/time_pattern'

module TimeZond
  class Rule
    attr_reader :name, :from_year, :to_year, :type, :on, :save, :letters, :offset

    def initialize(name:, from_year:, to_year:, type:, on:, save:, letters:, offset: TZOffset.zero)
      @name = name
      @from_year = from_year
      @to_year = to_year
      @type = type
      @on = on
      @save = save
      @letters = letters
      @offset = offset
    end

    def years
      from_year..to_year
    end
  end
end
