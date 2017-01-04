require 'bundler/setup'
require 'ruby-prof'
$:.unshift 'lib'
require 'time_zond'

zondzone = TimeZond::ZicFile.read('data/europe').zone('Europe/London')

t = Time.utc(2016, 5, 1, 14, 20)

RubyProf.start

100_000.times { zondzone.convert(t) }

res = RubyProf.stop
printer = RubyProf::GraphHtmlPrinter.new(res)

printer.print(File.open('profile/result.html', 'w'))
