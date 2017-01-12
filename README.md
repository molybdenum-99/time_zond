TimeZond
========

*TimeZond* is _investigative_ zoneinfo database wrapper. It answers the questions like
"what would this time look in that timezone?", as well as "what is time offsets used in this
timezone through 1964-1998?", "what are explanations for this strange time offset period?"
and so on.

It is not tries to be the replacement for [tzinfo](https://github.com/tzinfo/tzinfo) gem.
(See [Comparison with tzinfo](#comparison-with-tzinfo) section for some details.)
Instead, its targets are:

* simple, straightforward code; some kind of high-level reference implementation of the
  database:
  * like in source, there is a bunch of `Zone`s, consisting of `Period`s, each one either
    having single `TZOffset` (separate gem) or a couple of offset-changing `Rule`s;
* full, easy access to all database treasures, including
  * navigation through all available data, e.g. "in Europe/London timezone, what time offsets
    were registered through history, when the offsets were changed?.."
  * "bird view" to data, "what groups of timezones exist, to what countries they correspond,
    how deep in history database goes";
  * comments and explanations of db creators;
* inverstigate possibility for natural Ruby API for timezones, including:
  * create or parse time in context of this timezone;
  * convert time from current timezone to provided timezone;
  * guess what timezone this time could be.

Usage
-----

```ruby
# There is no default/global things. You should have load your database
db = TimeZond::ZoneInfo.read # from data provided with gem
# or
# db = TimeZond::ZoneInfo.read('./tzdata/2016j') # from your folder with (more recent?) data
# or
# db = TimeZond::ZoneInfo.read('tzdata2016j.tar.gz') # also works

# one zone
zone = db.zone('Europe/Kiev')
# => #<TimeZond::Zone Europe/Kiev (9 periods, +01:00 - +05:00)>

tm = Time.parse('1917-12-01 14:30 +0800')

# everyday usage
zone.convert(tm)
# => 2016-05-01 09:30:00 +0300
zone.local(2016, 5, 1)
# => 2016-05-01 00:00:00 +0300
zone.parse('2016-05-01')

# Navigation through zone components
# zone consists of periods
zone.periods # =>
# => [
#   #<TimeZond::Period::ByOffset +02:02:04 (until Jan 01, 1880)>,
#   #<TimeZond::Period::ByOffset +02:02:04 (until May 02, 1924)>,
#   #<TimeZond::Period::ByOffset +02:00 (until Jun 21, 1930)>,
#   #<TimeZond::Period::ByOffset +03:00 (until Sep 20, 1941)>,
#   #<TimeZond::Period::ByRules C-Eur+01:00 (until Nov 06, 1943)>,
#   #<TimeZond::Period::ByRules Russia+03:00 (until Jul 01, 1990)>,
#   #<TimeZond::Period::ByOffset +01:00+03:00 (until Sep 29, 1991)>,
#   #<TimeZond::Period::ByRules E-Eur+02:00 (until Jan 01, 1995)>,
#   #<TimeZond::Period::ByRules EU+02:00 (current)>
# ]

zone.current_period
# => #<TimeZond::Period::ByRules EU+02:00 (current)>
zone.period_at(tm)
# => #<TimeZond::Period::ByOffset +02:02:04 (until May 02, 1924)>
# zone.period_at(2016, 6, 1, 14, 30)

# each period either has one offset ("save"), or list of associated rules:
zone.periods.first.rules # => #<TZOffset +00:00>
zone.periods.last.rules
# => [
#   #<TimeZond::Rule(EU) 1977-1980, since Apr, first Sun at 01:00:00: +01:00>,
#   #<TimeZond::Rule(EU) 1977, since Sep, last Sun at 01:00:00: +00:00>,
#   #<TimeZond::Rule(EU) 1978, since Oct, 1 at 01:00:00: +00:00>,
#   #<TimeZond::Rule(EU) 1979-1995, since Sep, last Sun at 01:00:00: +00:00>,
#   #<TimeZond::Rule(EU) 1981-..., since Mar, last Sun at 01:00:00: +01:00>,
#   #<TimeZond::Rule(EU) 1996-..., since Oct, last Sun at 01:00:00: +00:00>
# ]

# group of zones
group = db.group('America')
group = db.group('America/Argentina')
group = db.group('America').group('Argentina')

# find zone(s) for country
db.country('Ukraine') # => zone group
# 2-letter ISO codes work
db.counry('UA')
# check all:
db.countries
db.country_codes

# group of abbreviated zones
db.abbreviations
# group of "links" -- zones that are just referencing others
db.links
# also works:
db.country('Ukraine').links
# All zone groups can act as a whole DB:
db.country('Ukraine').links.zone('...')
```

### Working with ZoneInfo documentation

```ruby
db = TimeZond::ZoneInfo.read # (docs: true)

zone = db.zone('Europe/Kiev')
# => #<TimeZond::Zone Europe/Kiev (9 periods, +01:00 - +05:00) # Most of Ukraine since 1970 ...>
puts zone.comments
# Most of Ukraine since 1970 has been like Kiev.
# "Kyiv" is the transliteration of the Ukrainian name, but "Kiev" is more common in English.
zone.periods[1] # => #<TimeZond::Period::ByOffset(KMT) +02:02:04 (until May 02, 1924) # Kiev Mean Time>

zone.section
# => #<TimeZond::Docs::Section(Ukraine): 5 comments>
zone.section.comments
# => [
#   #<TimeZond::Docs::Comment: From Igor Karpov, who works...>,
#   #<TimeZond::Docs::Comment(Alexander Krivenyshev, 2011-09-20): On September 20, 2011 the d...>,
#   #<TimeZond::Docs::Comment(Philip Pizzey, 2011-10-18): Today my Ukrainian colleagu...>,
#   #<TimeZond::Docs::Comment(Udo Schwedt, 2011-10-18): As far as I understand, the...>,
#   #<TimeZond::Docs::Comment(Vladimir in Moscow via Alois Treindl re Kiev time 1991/2, 2014-02-28): First in Ukraine they chang...>
# ]

c = zone.section.comments[1]
# => #<TimeZond::Docs::Comment(Alexander Krivenyshev, 2011-09-20): On September 20, 2011 the d...>

c.author # => Alexander Krivenyshev
c.date # => #<Date: 2011-09-20 ((2455825j,0s,0n),+0s,2299161j)>

puts c
# From Alexander Krivenyshev (2011-09-20):
# On September 20, 2011 the deputies of the Verkhovna Rada agreed to abolish the transfer clock to winter time.
#
# Bill No. 8330 of MP from the Party of Regions Oleg Nadoshi got approval from 266 deputies.
#
# Ukraine abolishes transfer back to the winter time (in Russian) http://news.mail.ru/politics/6861560/
#
# The Ukrainians will no longer change the clock (in Russian) http://www.segodnya.ua/news/14290482.html
#
# Deputies cancelled the winter time (in Russian) http://www.pravda.com.ua/rus/news/2011/09/20/6600616/

# Comment groups explanations......
# All available comment groups:

# Note, that comment groups are not exactly equal neither to countries from iso3166, nor to
# groups, like America/... They are more vague and ad-hoc, but also more semantic sometimes.

db.comment_group(/Denmark/) # Bingo!
```

Comparizon with `tzinfo`
------------------------

*Introductory note*: As already stated above, TimeZond is _not_ meant to be a replacement to
`tzinfo`, so the latter is most probably more effective in all situations, both by performance
and memory usage. TimeZond's strength is more featureful API and ability to discover aspects
of zoneinfo database.
