require 'time_zond/util/time_pattern'

module TimeZond
  describe Util::TimePattern do
    describe '.parse' do
    end

    describe Util::TimePattern::Day do
      subject(:pattern) {
        described_class.new(
          mon: 9,
          day: 10,
          hour: 2,
          min: 0,
          offset: TZOffset.parse('+2')
        )
      }

      its(:inspect) { is_expected.to eq '#<TimeZond::Util::TimePattern Sep, 10, 02:00:00+02:00>' }

      it 'always calculates the same day' do
        expect(pattern.year(1984)).to eq Time.parse('1984-09-10 02:00 +02')
        expect(pattern.year(2016)).to eq Time.parse('2016-09-10 02:00 +02')
      end
    end

    describe Util::TimePattern::LastWeekday do
      subject(:pattern) {
        described_class.new(
          mon: 9,
          wday: 0,
          hour: 2,
          min: 0,
          offset: TZOffset.parse('+2')
        )
      }

      its(:inspect) { is_expected.to eq '#<TimeZond::Util::TimePattern Sep, last Sunday, 02:00:00+02:00>' }

      it 'calculates correct week day' do
        expect(pattern.year(1984)).to eq Time.parse('1984-09-30 02:00 +02')
        expect(pattern.year(2016)).to eq Time.parse('2016-09-25 02:00 +02')
      end
    end

    describe Util::TimePattern::WeekdayAfter do
      subject(:pattern) {
        described_class.new(
          mon: 9,
          wday: 1,
          after: 12,
          hour: 2,
          min: 0,
          offset: TZOffset.parse('+2')
        )
      }

      its(:inspect) { is_expected.to eq '#<TimeZond::Util::TimePattern Sep, Monday >= 12, 02:00:00+02:00>' }

      it 'calculates correct week day' do
        expect(pattern.year(1984)).to eq Time.parse('1984-09-17 02:00 +02')
        expect(pattern.year(2016)).to eq Time.parse('2016-09-12 02:00 +02')
      end
    end
  end
end
