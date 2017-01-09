require 'time_zond/zic_file/parse_context'

module TimeZond
  describe ZicFile::ParseContext do
    subject(:ctx) { described_class.new }

    describe '#file' do
      before { ctx.file('europe') }

      its(:current_object) { is_expected
        .to be_a(ZicFile::ParseContext::File)
        .and have_attributes(title: 'europe')
      }
    end

    describe '#section' do
      before { ctx.section('Argentina') }

      its(:current_object) { is_expected
        .to be_a(ZicFile::ParseContext::Section)
        .and have_attributes(title: 'Argentina')
      }
      its(:'sections.count') { is_expected.to eq 1 }
    end

    describe '#comment' do
      context 'regular' do
        context 'when there is no current object'

        context 'when there is current object' do
          before {
            ctx.section('Ukraine')
            ctx.comment('FUUBAR')
            ctx.comment('And the next line')
          }
          its(:'current_object.comment') { is_expected.to eq "FUUBAR\nAnd the next line" }
        end
      end

      context 'start of zones' do
        before { ctx.comment('Zone	NAME		GMTOFF	RULES	FORMAT	[UNTIL]') }

        its(:current_object) { is_expected
          .to be_a(ZicFile::ParseContext::Comment)
          .and have_attributes(scope: :zone, comment: '')
        }
      end

      context 'start of rules' do
        before { ctx.comment('Rule	NAME	FROM	TO	TYPE	IN	ON	AT	SAVE	LETTER/S') }

        its(:current_object) { is_expected
          .to be_a(ZicFile::ParseContext::Comment)
          .and have_attributes(scope: :rule, comment: '')
        }
      end

      context 'end of context' do
        before {
          ctx.file('europe')
          ctx.comment('Zone	NAME		GMTOFF	RULES	FORMAT	[UNTIL]')
          ctx.comment('###############################################################################')
        }

        its(:current_object) { is_expected
          .to be_a(ZicFile::ParseContext::File)
          .and have_attributes(title: 'europe')
        }
      end
    end

    describe '#zone' do
      context 'base' do
        before { ctx.zone(%w[Europe/Kiev 2:02:04 - LMT 1880]) }

        its(:current_object) { is_expected
          .to be_a(ZicFile::ParseContext::Comment)
          .and have_attributes(scope: :period, comment: '')
        }
        its(:'zones.count') { is_expected.to eq 1 }
        its(:current_zone) { is_expected
          .to be_a(ZicFile::ParseContext::Zone)
          .and have_attributes(name: 'Europe/Kiev')
        }
        its(:'current_zone.periods') { are_expected
          .to contain_exactly(an_instance_of(ZicFile::ParseContext::Period).and have_attributes(data: %w[2:02:04 - LMT 1880]))
        }
      end

      context 'when comment section exists' do
        before {
          ctx.section('Ukraine')
          ctx.zone(%w[Europe/Kiev 2:02:04 - LMT 1880])
        }
        its(:'current_zone.section') { is_expected.to have_attributes(title: 'Ukraine') }
      end

      context 'when comment object exists' do
        before {
          ctx.comment('Zone	NAME		GMTOFF	RULES	FORMAT	[UNTIL]')
          ctx.comment('This is Spartaaa!')
          ctx.zone(%w[Europe/Kiev 2:02:04 - LMT 1880])
        }
        its(:'current_zone.comment') { is_expected.to eq 'This is Spartaaa!' }
      end

      context 'when first period is commented' do
        before { ctx.zone(%w[Europe/Kiev 2:02:04 - LMT 1880], comment: 'LMT what?') }
        its(:'current_zone.periods.first') { is_expected
          .to have_attributes(data: %w[2:02:04 - LMT 1880], comment: 'LMT what?')
        }
      end
    end

    describe '#period' do
      context 'when no current zone exists' do
      end

      context 'when current zone exists' do
        before { ctx.zone(%w[Europe/Kiev 2:02:04 - LMT 1880]) }
        subject { ctx.current_zone.periods.last }

        context 'plain' do
          before { ctx.period(%w[2:02:04 - KMT 1924 May  2]) }

          it { is_expected
            .to be_a(ZicFile::ParseContext::Period)
            .and have_attributes(data: %w[2:02:04 - KMT 1924 May  2])
          }
        end

        context 'when period is commented inline' do
          before { ctx.period(%w[2:02:04 - KMT 1924 May  2], comment: 'Kiev Mean Time') }
          it { is_expected
            .to be_a(ZicFile::ParseContext::Period)
            .and have_attributes(data: %w[2:02:04 - KMT 1924 May  2], comment: 'Kiev Mean Time')
          }
        end

        context 'when comment object for period exists' do
          before {
            ctx.comment('Kiev Mean Time')
            ctx.period(%w[2:02:04 - KMT 1924 May  2], comment: '...or something')
          }
          it { is_expected
            .to be_a(ZicFile::ParseContext::Period)
            .and have_attributes(data: %w[2:02:04 - KMT 1924 May  2], comment: "Kiev Mean Time\n...or something")
          }
          it { expect(ctx.current_object).to have_attributes(scope: :period, comment: '') }
        end
      end
    end

    describe '#rule' do
      let(:data) { %w[Turkey	1981	1982	-	Mar	lastSun	3:00	1:00	S] }

      context 'base' do
        before { ctx.rule(data) }

        its(:current_object) { is_expected
          .to be_a(ZicFile::ParseContext::Comment)
          .and have_attributes(scope: :rule, comment: '')
        }
        its(:'rules.count') { is_expected.to eq 1 }
        its(:'rules.last') { is_expected
          .to be_a(ZicFile::ParseContext::Rule)
          .and have_attributes(data: data)
        }
      end

      context 'when comment section exists' do
        before {
          ctx.section('Ukraine')
          ctx.rule(data)
        }
        its(:'rules.last.section') { is_expected.to have_attributes(title: 'Ukraine') }
      end

      context 'when comment object exists' do
        before {
          ctx.comment('Rule	NAME	FROM	TO	TYPE	IN	ON	AT	SAVE	LETTER/S')
          ctx.comment('No idea, honestly')
          ctx.rule(data, comment: 'And nobody has')
        }
        its(:'rules.last.comment') { is_expected.to eq "No idea, honestly\nAnd nobody has" }
      end
    end
  end
end
