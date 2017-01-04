require 'time_zond/zic_file'

module TimeZond
  describe ZicFile do
    context 'europe' do
      subject(:file) { ZicFile.read('spec/fixtures/europe') }

      describe '#zone_data' do
        its(:zone_data) { is_expected.to be_a(Hash) }
        its(:'zone_data.keys') { are_expected.to include(*%w[Europe/London Europe/Dublin Europe/Andorra]) }

        describe 'one zone' do
          subject { file.zone_data['Europe/London'] }

          it { is_expected.to eq [
            %w[-0:01:15 - LMT 1847 Dec  1  0:00s],
            %w[0:00 GB-Eire %s 1968 Oct 27],
            %w[1:00 - BST 1971 Oct 31  2:00u],
            %w[0:00 GB-Eire %s 1996],
            %w[0:00 EU GMT/BST]
          ] }
        end
      end

      describe '#rule_data' do
        its(:rule_data) { is_expected.to be_a(Hash) }
        its(:'rule_data.keys') { are_expected.to include(*%w[GB-Eire C-Eur E-Eur Russia]) }

        describe 'one rule' do
          subject { file.rule_data['Austria'] }

          it { is_expected.to eq [
            %w[1920 only - Apr  5 2:00s 1:00 S],
            %w[1920 only - Sep 13 2:00s 0 -],
            %w[1946 only - Apr 14 2:00s 1:00 S],
            %w[1946 1948 - Oct Sun>=1 2:00s 0 -],
            %w[1947 only - Apr  6 2:00s 1:00 S],
            %w[1948 only - Apr 18 2:00s 1:00 S],
            %w[1980 only - Apr  6 0:00 1:00 S],
            %w[1980 only - Sep 28 0:00 0 -]
          ] }
        end
      end

      describe '#link_data'

      describe '#zone' do
        subject(:zone) { file.zone('Europe/London') }

        it { is_expected.to be_a Zone }
        its(:name) { is_expected.to eq 'Europe/London' }
        its(:periods) { are_expected
          .to be_an(Array)
          .and have_attributes(length: 5)
          .and all be_a(Period)
        }

        context 'single period' do
          subject(:period) { zone.periods.last }

          its(:rules) { is_expected.to eq 'EU' }
          its(:gmt_off) { is_expected.to eq TZOffset.zero }
          its(:format) { is_expected.to eq 'GMT/BST' }

          its(:rule_set) { is_expected.to eq file.rules('EU') }
        end

        it 'parses each zone only once'
        context 'when zone not found'
      end
    end
  end
end
