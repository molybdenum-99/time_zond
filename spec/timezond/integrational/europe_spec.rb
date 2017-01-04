module TimeZond
  describe 'Europe zones' do
    before { Parser.new.file('data/europe') }
    after { Zone.all.clear }

    describe 'Kiev' do
      subject(:zone) { Zone.all['Europe/Kiev'] }

      describe 'periods' do
        subject { zone.periods }

        its(:count) { is_expected.to eq 9 }
        its_map(:inspect) { is_expected.to eq [
          '#<TimeZond::Period ...-1880/01/01 +02:02:04>',
          '#<TimeZond::Period 1880/01/01-1924/05/02 +02:02:04>',
          '#<TimeZond::Period 1924/05/02-1930/06/21 +02:00>',
          '#<TimeZond::Period 1930/06/21-1941/09/20 +03:00>',
          '#<TimeZond::Period 1941/09/20-1943/11/06 +01:00-+02:00>',
          '#<TimeZond::Period 1943/11/06-1990/06/01 +03:00-+04:00>',
          '#<TimeZond::Period 1990/06/01-1991/09/29 +03:00>',
          '#<TimeZond::Period 1991/09/29-1995/01/01 +02:00-+03:00>',
          '#<TimeZond::Period 1995/01/01-... +02:00-+03:00>',
        ]}
      end
    end
  end
end
