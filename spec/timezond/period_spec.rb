module TimeZond
  describe Period do
    let(:zic_file) { double }
    let(:off) { TZOffset.parse('07:15:20') }

    subject(:period) {
      described_class.new(
        zic_file,
        gmt_off: '07:15:20', # we use "weird" offset here to no local testing environment definitely not match it
        rules: rules,
        format: 'CET'
      )
    }

    context 'no rules' do
      let(:rules) { '-' }

      describe '#initialize' do
        its(:gmt_off) { is_expected.to eq off }
        its(:rules) { is_expected.to eq TZOffset.zero }
      end

      describe '#local' do
        it 'calculates local with respect to offset' do
          expect(period.local(2016, 5, 1)).to eq Time.new(2016, 5, 1, 0, 0, 0, off.to_i)
        end
      end

      describe '#convert' do
        let(:tm) { Time.parse('2016-06-01 14:30:00 +03') }

        it 'converts data between timezones' do
          expect(period.convert(tm)).to eq Time.new(2016, 6, 1, 18, 45, 20, off.to_i)
        end
      end

      describe '#inspect' do
        its(:inspect) { is_expected.to eq '#<TimeZond::Period gmt_off=+07:15:20 rules=+00:00 format=CET>' }
      end

      xdescribe '#format'
    end

    context 'offset rules' do
      let(:rules) { '1:00' }

      describe '#initialize' do
        its(:gmt_off) { is_expected.to eq off }
        its(:rules) { is_expected.to eq TZOffset.parse(rules) }
      end

      describe '#local' do
        it 'calculates local with respect to offset' do
          expect(period.local(2016, 5, 1)).to eq Time.new(2016, 5, 1, 0, 0, 0, off.to_i + 3600)
        end
      end

      describe '#convert' do
        let(:tm) { Time.parse('2016-06-01 14:30:00 +03') }

        it 'converts data between timezones' do
          expect(period.convert(tm)).to eq Time.new(2016, 6, 1, 19, 45, 20, off.to_i + 3600)
        end
      end

      describe '#inspect' do
        its(:inspect) { is_expected.to eq '#<TimeZond::Period gmt_off=+07:15:20 rules=+01:00 format=CET>' }
      end

      xdescribe '#format'
    end

    context 'named rules' do
      let(:rules_array) {[
        Rule.from_a(%w[Austria 1920 only - Apr  5 2:00s 1:10 S]),
        Rule.from_a(%w[Austria 1920 only - Sep 13 2:00s 2:15 -])
      ]}
      before {
        allow(zic_file).to receive(:rules).with('Austria').and_return(rules_array)
      }
      let(:rules) { 'Austria' }

      describe '#initialize' do
      end

      describe '#local' do
        context 'before any of the rules' do
          it 'uses default offset' do
            expect(period.local(1920, 3, 1)).to eq Time.new(1920, 3, 1, 0, 0, 0, off.to_i)
          end
        end

        context 'inside the area of one rule' do
          it 'uses rule offset' do
            expect(period.local(1920, 6, 1)).to eq Time.new(1920, 6, 1, 0, 0, 0, (off + TZOffset.parse('1:10')).to_i)
          end
        end

        context 'inside the area of several rules' do
          it 'uses last rule offset' do
            expect(period.local(1920, 10, 1)).to eq Time.new(1920, 10, 1, 0, 0, 0, (off + TZOffset.parse('2:15')).to_i)
          end
        end

        context 'after the last rule' do
          it 'uses last rule offset' do
            expect(period.local(1921, 10, 1)).to eq Time.new(1921, 10, 1, 0, 0, 0, (off + TZOffset.parse('2:15')).to_i)
          end
        end
      end

      describe '#convert' do
      end

      describe '#format'
      describe '#inspect' do
        its(:inspect) { is_expected.to eq '#<TimeZond::Period gmt_off=+07:15:20 rules=Austria format=CET>' }
      end
    end

    describe 'until processing'
  end
end

__END__
  describe Period do
    let(:parser) { Parser.new }

    subject(:period) {
      described_class.new(
        till: Time.parse('1963 Apr 14'),
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
        till: Time.parse('1940 Feb 25 2:00'),
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

    xdescribe '#inspect' do
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
