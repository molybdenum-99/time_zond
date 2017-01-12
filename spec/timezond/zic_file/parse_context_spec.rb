require 'time_zond/zic_file/parse_context'

module TimeZond
  describe ZicFile::ParseContext do
    subject(:ctx) { described_class.new('europe') }

    describe '#initialize' do
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

      context 'when unclaimed zones/periods comment exist' do
      end
    end

    describe '#comment' do
      context 'regular' do
        before {
          ctx.section('Ukraine')
          ctx.comment('FUUBAR.')
          ctx.comment('And the next line')
        }
        its(:'current_object.comments.last.text') { is_expected.to eq "FUUBAR.\nAnd the next line" }
        # TODO: test comment joining/not joining.
      end

      context 'start of zones' do
        before { ctx.comment('Zone	NAME		GMTOFF	RULES	FORMAT	[UNTIL]') }

        its(:current_object) { is_expected
          .to be_a(ZicFile::ParseContext::Comment)
          .and have_attributes(scope: :zone)
        }
      end

      context 'start of rules' do
        before { ctx.comment('Rule	NAME	FROM	TO	TYPE	IN	ON	AT	SAVE	LETTER/S') }

        its(:current_object) { is_expected
          .to be_a(ZicFile::ParseContext::Comment)
          .and have_attributes(scope: :rule)
        }
      end

      context 'end of context' do
        before {
          ctx.comment('Zone	NAME		GMTOFF	RULES	FORMAT	[UNTIL]')
          ctx.comment('###############################################################################')
        }

        its(:current_object) { is_expected
          .to be_a(ZicFile::ParseContext::File)
          .and have_attributes(title: 'europe')
        }
      end

      context 'start of signed comment' do
        before { ctx.comment('From Paul Eggert (2005-06-11):') }

        its(:'current_object.comments.last') { is_expected
          .to be_a(ZicFile::ParseContext::CommentPart)
          .and have_attributes(author: 'Paul Eggert', date: '2005-06-11', text: '')
        }
      end

      context 'start of signed comment - with continuation' do
        before {
          ctx.comment('From Gwillim Law (2001-06-06), citing')
          ctx.comment('<http://www.statkart.no/efs/efshefter/2001/efs5-2001.pdf> (2001-03-15),')
        }

        its(:'current_object.comments.last') { is_expected
          .to be_a(ZicFile::ParseContext::CommentPart)
          .and have_attributes(
            author: 'Gwillim Law',
            date: '2001-06-06',
            text: 'citing <http://www.statkart.no/efs/efshefter/2001/efs5-2001.pdf> (2001-03-15),'
          )
        }
      end
    end

    describe '#zone' do
      context 'base' do
        before { ctx.zone(%w[Europe/Kiev 2:02:04 - LMT 1880]) }

        its(:current_object) { is_expected
          .to be_a(ZicFile::ParseContext::Comment)
          .and have_attributes(scope: :period)
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
        its(:'current_zone.section') { is_expected.to eq 'Ukraine' }
      end

      context 'when comment object exists' do
        before {
          ctx.comment('Zone	NAME		GMTOFF	RULES	FORMAT	[UNTIL]')
          ctx.comment('This is Spartaaa!')
          ctx.zone(%w[Europe/Kiev 2:02:04 - LMT 1880])
        }
        its(:'current_zone.comments.last.text') { is_expected.to eq 'This is Spartaaa!' }
      end

      context 'when first period is commented' do
        before { ctx.zone(%w[Europe/Kiev 2:02:04 - LMT 1880], comment: 'LMT what?') }
        its(:'current_zone.periods.first') { is_expected
          .to have_attributes(data: %w[2:02:04 - LMT 1880], comment: 'LMT what?')
        }
      end

      context 'when current period comment is existing' do
        before {
          ctx.comment('Zone	NAME		GMTOFF	RULES	FORMAT	[UNTIL]')
          ctx.zone(%w[Europe/Kiev 2:02:04 - LMT 1880])
          ctx.comment('Ruthenia used CET 1990/1991.')
          ctx.zone(%w[Europe/Uzhgorod 1:29:12 - LMT 1890 Oct])
        }
        its(:'current_zone.comments.last.text') { is_expected.to eq 'Ruthenia used CET 1990/1991.' }
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
            .and have_attributes(
              data: %w[2:02:04 - KMT 1924 May  2],
              comments: array_including(have_attributes(text: 'Kiev Mean Time'))
            )
          }
        end

        context 'when comment object for period exists' do
          before {
            ctx.comment('Kiev Mean Time')
            ctx.period(%w[2:02:04 - KMT 1924 May  2], comment: '...or something')
          }
          it { is_expected
            .to be_a(ZicFile::ParseContext::Period)
            .and have_attributes(
              data: %w[2:02:04 - KMT 1924 May  2],
              comments: array_including(have_attributes(text: 'Kiev Mean Time'), have_attributes(text: '...or something'))
            )
          }
          it { expect(ctx.current_object)
            .to have_attributes(
              scope: :period,
              comments: [ZicFile::ParseContext::CommentPart.new]
            )
          }
        end
      end
    end

    describe '#rule' do
      let(:data) { %w[Turkey	1981	1982	-	Mar	lastSun	3:00	1:00	S] }

      context 'base' do
        before { ctx.rule(data) }

        its(:current_object) { is_expected
          .to be_a(ZicFile::ParseContext::Comment)
          .and have_attributes(scope: :rule)
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
        its(:'rules.last.comments') { is_expected
          .to match_array([
            have_attributes(text: "No idea, honestly"),
            have_attributes(text: "And nobody has")
          ])
        }
      end
    end
  end
end
