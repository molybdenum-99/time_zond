require 'bundler/setup'
require 'tzinfo'
$:.unshift 'lib'
require 'time_zond'

require 'benchmark/memory'

t = Time.utc(2016, 5, 1, 14, 20)

Benchmark.memory do |b|
  b.report('tzinfo') {
    TZInfo::Timezone.get('Europe/London').utc_to_local(t)
  }
  b.report('timezond') {
    TimeZond::ZicFile.read('data/europe').zone('Europe/London').convert(t)
  }

  b.compare!
end
