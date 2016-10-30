module TimeZond
  class Parser
    def time_pattern(mon, day, time, standard: TZOffset.zero, local: TZOffset.zero)
      # TODO: validations

      mon = Date::ABBR_MONTHNAMES.index(mon)
      hour, min = time.split(':').map(&:to_i)

      offset =
        case time.scan(/[a-z]?$/).first
        when 'u', 'g', 'z'
          TZOffset.zero
        when 's'
          standard
        when 'w', ''
          local
        else
          fail ArgumentError, "Unparseable time locale: #{time.inspect}"
        end

      case day
      when /^\d+$/
        Util::TimePattern::Day.new(mon: mon, day: day.to_i, hour: hour, min: min, offset: offset)
      when /^last(\S+)$/
        wday = Date::ABBR_DAYNAMES.index(Regexp.last_match[1])
        Util::TimePattern::LastWeekday.new(mon: mon, wday: wday, hour: hour, min: min, offset: offset)
      when /^(\S+)>=(\d+)$/
        after = Regexp.last_match[2].to_i
        wday = Date::ABBR_DAYNAMES.index(Regexp.last_match[1])
        Util::TimePattern::WeekdayAfter.new(mon: mon, wday: wday, after: after, hour: hour, min: min, offset: offset)
      else
        fail ArgumentError, "Unparseable day pattern: #{day.inspect}"
      end
    end

    def rules
      @rules ||= Hash.new { |h, k| h[k] = [] }
    end

    def rule(name, from_year, to_year, type, mon, on, at, save, letters, offset: TZOffset.zero)
      to_year = from_year if to_year == 'only'
      type = nil if type == '-'
      letters = '' if type == '-'
      save = TZOffset.parse(save)

      Rule.new(
        name: name,
        from_year: from_year.to_i,
        to_year: to_year.to_i,
        type: type,
        on: time_pattern(mon, on, at, standard: offset, local: offset + save),
        save: save,
        offset: offset + save,
        letters: letters
      ).tap { |r| rules[name] << r }
    end

    def period(offset, rules_name, format, *until_parts)
      Period.new(
        offset: TZOffset.parse(offset),
        rules: rules_name == '-' ? [] : rules.fetch(rules_name),
        format: format,
        to: Time.parse(until_parts.join(' '))
      )
    end

    def zone(name, *first_period)
      Zone.new(name, [period(*first_period)])
    end
  end
end
