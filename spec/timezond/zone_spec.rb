module TimeZond
  describe Zone do

    describe 'calculations' do
      let(:zone) { ZicFile.read('spec/fixtures/europe').zone('Europe/London') }

      describe '#local' do
        subject { zone.local(*components) }

        context 'into the last period' do
          context 'non-DST' do
            let(:components) { [2017, 1, 3] }
            it { is_expected.to eq Time.new(2017, 1, 3, 0, 0, 0, '+00:00') }
          end

          context 'DST' do
            let(:components) { [2017, 8, 3] }
            it { is_expected.to eq Time.new(2017, 8, 3, 0, 0, 0, '+01:00') }
          end
        end

        context 'before the first period' do
          let(:components) { [1617, 8, 3] }
          it { is_expected.to eq TZOffset.parse('-0:01:15').local(1617, 8, 3, 0, 0, 0) }
        end

        context 'inside the periods' do
          let(:components) { [1971, 10, 3] }
          it { is_expected.to eq Time.new(1971, 10, 3, 0, 0, 0, '+01:00') }
        end

        context 'edge cases' do
          # Period of +1 ends at: 1971 Oct 31 2:00u (where "u" means UTC)
          # ...from that period PoV, this would calculate to period end 03:00 +01, e.g. 02:00 UTC
          # (and thus, should switch to new):
          context 'border in old period' do
            let(:components) { [1971, 10, 31, 3] }
            it { is_expected.to eq Time.new(1971, 10, 31, 3, 0, 0, '+00:00') }
          end

          # ...and from the period PoV, this is inside the period: 02:00 +01, e.g. 01:00 UTC
          # (and thus, should be the old period)
          context 'border in new period' do
            let(:components) { [1971, 10, 31, 2] }
            it { is_expected.to eq Time.new(1971, 10, 31, 2, 0, 0, '+01:00') }
          end
        end
      end

      describe '#convert' do
      end

      describe '#now'
    end

    describe '#inspect'

    describe '#periods' do
    end

    describe '#period_for'

    describe '#offset_for'

    describe '.guess'

    describe '.locate'
  end
end
