require 'time_zond/rule'

module TimeZond
  describe Rule do
    describe '#activated_at' do
      let(:rule) { described_class.new(from: '2016', in: 'May', on: on, at: at, save: '+1') }
      let(:at) { '14:00u' }
      let(:on) { '15' }
      let(:standard) { TZOffset.parse('+3') }

      subject { rule.activated_at(year, standard) }

      context 'when years before' do
        let(:year) { 2015 }
        it { is_expected.to be_nil }
      end

      context 'when this year' do
        let(:year) { 2016 }

        context 'constant day activation' do
          it { is_expected.to eq Time.utc(2016, 5, 15, 14, 0) }
        end

        context 'weekday after date activation' do
          let(:on) { 'Sun>=20' }
          it { is_expected.to eq Time.utc(2016, 5, 22, 14, 0) }
        end

        context 'last weekday activation' do
          let(:on) { 'lastSun' }
          it { is_expected.to eq Time.utc(2016, 5, 29, 14, 0) }
        end

        context 'utc time' do
          let(:at) { '14:00u' }

          it { is_expected.to eq Time.utc(2016, 5, 15, 14, 0) }
        end

        context 'standard time' do
          let(:at) { '14:00s' }

          it { is_expected.to eq Time.new(2016, 5, 15, 14, 0, 0, '+03:00') }
        end

        context 'local time' do
          let(:at) { '14:00' }

          it { is_expected.to eq Time.new(2016, 5, 15, 14, 0, 0, '+04:00') }
        end
      end

      context 'when years after' do
        let(:year) { 2017 }

        it { is_expected.to eq Time.utc(2016, 5, 15, 14, 0) }
      end
    end
  end
end
