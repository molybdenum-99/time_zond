require 'time_zond/period'

module TimeZond
  describe Period do
    let(:parser) { Parser.new }

    subject(:period) {
      described_class.new(
        from: Time.parse('1956 Jan 29'),
        to: Time.parse('1963 Apr 14'),
        offset: TZOffset.parse('01:00'),
        format: 'CET',
        rules: []
      )
    }

    let(:rules) {
      %q[
        Algeria	1916	only	-	Jun	14	23:00s	1:00	S
        Algeria	1916	1919	-	Oct	Sun>=1	23:00s	0	-
        Algeria	1917	only	-	Mar	24	23:00s	1:00	S
        Algeria	1918	only	-	Mar	 9	23:00s	1:00	S
        Algeria	1919	only	-	Mar	 1	23:00s	1:00	S
        Algeria	1920	only	-	Feb	14	23:00s	1:00	S
        Algeria	1920	only	-	Oct	23	23:00s	0	-
        Algeria	1921	only	-	Mar	14	23:00s	1:00	S
        Algeria	1921	only	-	Jun	21	23:00s	0	-
        Algeria	1939	only	-	Sep	11	23:00s	1:00	S
        Algeria	1939	only	-	Nov	19	 1:00	3:00	-
      ]
      .split("\n").map(&:strip).reject(&:empty?)
      .map { |s| parser.rule(*s.split(/\s+/)) }
    }

    let(:period_with_rules) {
      described_class.new(
        from: Time.parse('1911 Mar 11'),
        to: Time.parse('1940 Feb 25 2:00'),
        offset: TZOffset.parse('0:00'),
        format: 'WE%sT',
        rules: rules
      )
    }

    describe '#match?' do
    end

    describe '#local' do
      subject { period.local(1960, 10, 15, 3, 0) }

      it { is_expected.to eq Time.parse('1960-10-15 03:00:00+01') }

      context 'with rules' do
        it 'uses appropriate rule' do
          # 1916-1919, no DST
          expect(period_with_rules.local(1917, 11, 20)).to eq Time.parse('1917-11-20 00:00:00 UTC')
          # 1916-1919, DST
          expect(period_with_rules.local(1917, 3, 25)).to eq Time.parse('1917-03-25 00:00:00+01')
          # the last rule!
          expect(period_with_rules.local(1940, 2, 24)).to eq Time.parse('1940-02-24 00:00:00+03')
        end
      end

      it 'fails when outside period' do
        expect { period.local(2016) }.to raise_error ArgumentError
        expect { period.local(1920) }.to raise_error ArgumentError
      end
    end

    describe '#convert' do
      it 'fails when outside period' do
      end
    end

    describe '#now' do
      it 'fails on non-current period' do
      end
    end

    describe '#parse' do
    end

    describe '#inspect' do
      its(:inspect) { is_expected.to eq '#<TimeZond::Period 1956/01/29-1963/04/14 +01:00>' }

      context 'with rules' do
        subject { period_with_rules }

        its(:inspect) { is_expected.to eq '#<TimeZond::Period 1911/03/11-1940/02/25 +00:00-+03:00>' }
      end

      context 'without from' do
        subject(:period) {
          described_class.new(
            to: Time.parse('1963 Apr 14'),
            offset: TZOffset.parse('01:00'),
            format: 'CET',
            rules: []
          )
        }

        its(:inspect) { is_expected.to eq '#<TimeZond::Period ...-1963/04/14 +01:00>' }
      end
    end

    describe '#format(tm)'
  end
end
