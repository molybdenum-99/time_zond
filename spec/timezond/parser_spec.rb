require 'time_zond/parser'

module TimeZond
  describe Parser do
    let(:parser) { described_class.new }

    describe '#time_pattern' do
      context 'exact day' do
        subject { parser.time_pattern('Sep', '9', '14:00') }

        it { is_expected.to eq Util::TimePattern::Day.new(mon: 9, day: 9, hour: 14, min: 0) }
      end

      context 'last weekday' do
        subject { parser.time_pattern('Sep', 'lastSun', '14:00') }

        it { is_expected.to eq Util::TimePattern::LastWeekday.new(mon: 9, wday: 0, hour: 14, min: 0) }
      end

      context 'weekday after' do
        subject { parser.time_pattern('Sep', 'Sun>=11', '14:00') }

        it { is_expected.to eq Util::TimePattern::WeekdayAfter.new(mon: 9, wday: 0, after: 11, hour: 14, min: 0) }
      end

      context 'offset guessing' do
        let(:standard) { TZOffset.parse('+1') }
        let(:local) { TZOffset.parse('+2') }

        context 'UTC time' do
          subject { parser.time_pattern('Sep', '9', '14:00u', standard: standard, local: local) }

          its(:offset) { is_expected.to eq TZOffset.zero }
        end

        context 'standard time' do
          subject { parser.time_pattern('Sep', '9', '14:00s', standard: standard, local: local) }

          its(:offset) { is_expected.to eq standard }
        end

        context 'wall time' do
          subject { parser.time_pattern('Sep', '9', '14:00w', standard: standard, local: local) }

          its(:offset) { is_expected.to eq local }
        end

        context 'by default' do
          subject { parser.time_pattern('Sep', '9', '14:00', standard: standard, local: local) }

          its(:offset) { is_expected.to eq local }
        end
      end
    end

    describe '#rule' do
      let(:data) { %w[Algeria	1916	1924	-	Jun	14	23:00s	1:00	S] }

      subject(:rule) { parser.rule(*data) }

      its(:name) { is_expected.to eq 'Algeria' }
      its(:from_year) { is_expected.to eq 1916 }
      its(:to_year) { is_expected.to eq 1924 }
      its(:type) { is_expected.to be_nil }
      its(:save) { is_expected.to eq TZOffset.parse('+1:00') }
      its(:on) { is_expected.to eq parser.time_pattern(*%w[Jun	14	23:00s]) }
      its(:letters) { is_expected.to eq 'S' }

      context 'full offset' do
        subject(:rule) { parser.rule(*data, offset: TZOffset.parse('+02:00')) }

        its(:offset) { is_expected.to eq TZOffset.parse('+03:00') }
        its(:on) { is_expected.to eq parser.time_pattern(*%w[Jun	14	23:00s], standard: TZOffset.parse('+02:00')) }
      end

      context 'only year' do
        let(:data) { %w[Algeria	1916	only	-	Jun	14	23:00s	1:00	S] }

        its(:to_year) { is_expected.to eq 1916 }
      end

      # TODO: spec also describes min(imum) and max(imum) years; "max" is used, actually! "min" also, but only in systemv legacy

      it 'registers rule' do
        subject
        expect(parser.rules['Algeria']).not_to be_empty
      end
    end

    describe '#period' do
      let(:data) { %w[1:00	-	CET	1963 Apr 14] }

      subject(:period) { parser.period(*data) }

      its(:offset) { is_expected.to eq TZOffset.parse('+1') }
      its(:rules) { is_expected.to be_empty }
      its(:format) { is_expected.to eq 'CET' }
      its(:to) { is_expected.to eq Time.parse('1963 Apr 14') }
      its(:from) { is_expected.to be_nil }

      context 'with rule names' do
        context 'when rule is defined' do
          let(:data) { %w[1:00	Algeria	CET	1963 Apr 14] }
          let(:rules) { double }

          before {
            allow(parser).to receive(:rules).and_return('Algeria' => rules)
          }

          its(:rules) { is_expected.to eq rules }
        end

        context 'when rule is not defined' do
        end
      end

      context 'with until containing only year' do
        let(:data) { %w[-1:34:04 -	LMT	1907] }
        its(:to) { is_expected.to eq Time.parse('1907-01-01') }
      end

      context 'with no until' do
        let(:data) { %w[1:00	-	CET] }
        its(:to) { is_expected.to be_nil }
      end

      context 'with offset instead of rule' do
        let(:data) { %w[-2:00	1:00	CVST	1945 Oct 15] }
        its(:offset) { is_expected.to eq TZOffset.parse('-1') }
      end
    end

    describe '#zone' do
      let(:data) { %w[Africa/Algiers	0:12:12 -	LMT	1891 Mar 15  0:01] }

      subject(:zone) { parser.zone(*data) }

      its(:name) { is_expected.to eq 'Africa/Algiers' }
      its(:periods) { is_expected.to eq [parser.period(*data[1..-1])] }

      it 'registers zones' do
        expect { subject }.to change { Zone.all.key?('Africa/Algiers') }.to true
      end
    end

    describe '#file' do
      context 'africa' do
        before { parser.file('spec/fixtures/africa') }

        it 'loads all zones' do
          expect(Zone.all.keys).to include(*%w[Africa/Algiers Atlantic/Cape_Verde Africa/Ndjamena])
        end

        context 'zone periods' do
          subject { Zone.all['Atlantic/Cape_Verde'].periods }

          its(:count) { is_expected.to eq 5 }
          its_map(:offset) { is_expected.to eq %w[-1:34:04 -2:00 -1:00 -2:00 -1:00].map(&TZOffset.method(:parse)) }
        end
      end

      context 'europe' do
        before { parser.file('spec/fixtures/europe') }

        it 'loads all zones' do
          expect(Zone.all.keys).to include(*%w[Europe/London Europe/Dublin Europe/Andorra])
        end

        context 'zone periods' do
          subject { Zone.all['Europe/London'].periods }

          its(:count) { is_expected.to eq 5 }
          its_map(:offset) { is_expected.to eq %w[-0:01:15 0:00 1:00 0:00 0:00].map(&TZOffset.method(:parse)) }
          its_map(:to) {
            is_expected.to eq ["1847 Dec 1 0:00", "1968 Oct 27", "1971 Oct 31 2:00", "1996 Jan 01"].map(&Time.method(:parse)) + [nil]
          }
        end
      end
    end

    describe '#folder' do
    end
  end
end
