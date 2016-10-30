require 'time_zond/util/time_pattern'

module TimeZond
  describe Util::TimePattern do
    describe '.parse' do
      context 'exact day' do
        subject { described_class.parse('Sep', '9', '14:00') }

        it { is_expected.to eq Util::TimePattern::Day.new(mon: 9, day: 9, hour: 14, min: 0) }
      end

      context 'last weekday' do
        subject { described_class.parse('Sep', 'lastSun', '14:00') }

        it { is_expected.to eq Util::TimePattern::LastWeekday.new(mon: 9, wday: 0, hour: 14, min: 0) }
      end

      context 'weekday after' do
        subject { described_class.parse('Sep', 'Sun>=11', '14:00') }

        it { is_expected.to eq Util::TimePattern::WeekdayAfter.new(mon: 9, wday: 0, after: 11, hour: 14, min: 0) }
      end

      context 'offset guessing' do
        let(:standard) { TZOffset.parse('+1') }
        let(:local) { TZOffset.parse('+2') }

        context 'UTC time' do
          subject { described_class.parse('Sep', '9', '14:00u', standard: standard, local: local) }

          its(:offset) { is_expected.to eq TZOffset.zero }
        end

        context 'standard time' do
          subject { described_class.parse('Sep', '9', '14:00s', standard: standard, local: local) }

          its(:offset) { is_expected.to eq standard }
        end

        context 'wall time' do
          subject { described_class.parse('Sep', '9', '14:00w', standard: standard, local: local) }

          its(:offset) { is_expected.to eq local }
        end

        context 'by default' do
          subject { described_class.parse('Sep', '9', '14:00', standard: standard, local: local) }

          its(:offset) { is_expected.to eq local }
        end
      end
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
