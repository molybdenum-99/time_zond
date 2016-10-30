require_relative 'util/time_pattern'

module TimeZond
  class Rule
    def self.parse(name, from_year, to_year, type, mon, on, at, save, letters, offset: TZOffset.zero)
      to_year = from_year if to_year == 'only'
      type = nil if type == '-'
      letters = '' if type == '-'
      save = TZOffset.parse(save)

      new(
        name: name,
        from_year: from_year.to_i,
        to_year: to_year.to_i,
        type: type,
        on: Util::TimePattern.parse(mon, on, at, standard: offset, local: offset + save),
        save: save,
        offset: offset + save,
        letters: letters
      )
    end

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
  end
end
