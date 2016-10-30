require 'time_zond/rule'

module TimeZond
  describe Rule do
    describe '.parse' do
      let(:data) { %w[Algeria	1916	1924	-	Jun	14	23:00s	1:00	S] }

      subject(:rule) {
        described_class.parse(*data)
      }

      its(:name) { is_expected.to eq 'Algeria' }
      its(:from_year) { is_expected.to eq 1916 }
      its(:to_year) { is_expected.to eq 1924 }
      its(:type) { is_expected.to be_nil }
      its(:save) { is_expected.to eq TZOffset.parse('+1:00') }
      its(:on) { is_expected.to eq Util::TimePattern.parse(*%w[Jun	14	23:00s]) }
      its(:letters) { is_expected.to eq 'S' }

      context 'full offset' do
        subject(:rule) { described_class.parse(*data, offset: TZOffset.parse('+02:00')) }

        its(:offset) { is_expected.to eq TZOffset.parse('+03:00') }
        its(:on) { is_expected.to eq Util::TimePattern.parse(*%w[Jun	14	23:00s], standard: TZOffset.parse('+02:00')) }
      end

      context 'only year' do
        let(:data) { %w[Algeria	1916	only	-	Jun	14	23:00s	1:00	S] }
        its(:to_year) { is_expected.to eq 1916 }
      end
    end

    describe '#match?(tm)' do
    end

    describe '#range(year)' do
    end
  end
end
