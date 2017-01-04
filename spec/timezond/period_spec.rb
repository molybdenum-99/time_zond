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
          expect(period.convert(tm))
            .to eq(Time.new(2016, 6, 1, 19, 45, 20, off.to_i + 3600))
            .and have_attributes(utc_offset: off.to_i + 3600)
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
        subject { period.convert(tm) }

        context 'before any of the rules' do
          let(:tm) { Time.parse('1920-03-01 13:30 +0300') }

          it { is_expected
            .to eq(Time.new(1920, 3, 1, 17, 45, 20, off.to_i))
            .and have_attributes(utc_offset: off.to_i)
          }
        end

        context 'inside the area of one rule' do
          let(:tm) { Time.parse('1920-06-01 13:30 +0300') }
          let(:converted_offset) { off + TZOffset.parse('1:10') }

          it { is_expected
            .to eq(Time.new(1920, 6, 1, 18, 55, 20, converted_offset.to_i))
            .and have_attributes(utc_offset: converted_offset.to_i)
          }
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

      describe '#format'
      describe '#inspect' do
        its(:inspect) { is_expected.to eq '#<TimeZond::Period gmt_off=+07:15:20 rules=Austria format=CET>' }
      end
    end

    describe 'until processing'
  end
end
