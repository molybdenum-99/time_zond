require 'bundler/setup'
require 'tzinfo'
$:.unshift 'lib'
require 'time_zond'

tzinfozone = TZInfo::Timezone.get('Europe/London')
zondzone = TimeZond::ZicFile.read('data/europe').zone('Europe/London')

require 'benchmark/ips'

t = Time.utc(2016, 5, 1, 14, 20)

Benchmark.ips do |b|
  b.report('tzinfo') { tzinfozone.utc_to_local(t) }
  b.report('timezond') { zondzone.convert(t) }

  b.compare!
end
