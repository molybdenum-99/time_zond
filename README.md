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
zone.current_period
zone.period_at(tm)
# zone.period_at(2016, 6, 1, 14, 30)

# each period either has one offset ("save"), or list of associated rules:
zone.periods.first.rules # =>
zone.periods.last.rules

# group of zones
group = db.group('America')
group = db.group('America/Argentina')

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
```

Comparizon with `tzinfo`
------------------------

*Introductory note*: As already stated above, TimeZond is _not_ meant to be a replacement to
`tzinfo`, so the latter is most probably more effective in all situations, both by performance
and memory usage. TimeZond's strength is more featureful API and ability to discover aspects
of zoneinfo database.
