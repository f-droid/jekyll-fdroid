# F-Droid's Jekyll Plugin

[![Gem Version](https://badge.fury.io/rb/jekyll-fdroid.svg)](https://rubygems.org/gems/jekyll-fdroid)

With this gem you can browse packages of a F-Droid repository in a Jekyll site.
Add the following configurations to your `_config.yml`:
```
gems:
  - jekyll-fdroid
  - jekyll-include-cache
  - jekyll-paginate-v2
fdroid-repo: https://guardianproject.info/fdroid/repo
```

`jekyll-include-cache` and `jekyll-paginate-v2` are needed to be added to the configuration manually
because we [weren't able to add the configuration programmatically](https://gitlab.com/fdroid/jekyll-fdroid/issues/29).

For default styling of the browsing and packages' pages
you need to import the plugin's stylesheet in your SASS file like this:
```
@import "jekyll-fdroid";
```

To show a list of latest or last updated packages,
use the following tags in your page:
```
{% fdroid_show_latest_packages %}
{% fdroid_show_last_updated_packages %}
```

## Running Tests

To run the test suite, you must first have installed the releveant dependencies:

```
bundle install --path vendor
```

The tests are then run via RSpec:

```
bundle exec rspec
```

If you want to exclude tests which hit the network to download F-Droid metadata, run:

```
bundle exec rspec --tag "~network"
```

## Can I use this plugin with the old index?

Starting at version 0.2.0 this plugin only supports the new JSON index
of F-Droid.
If you want to use this plugin with the old XML index,
you can use the [release 0.1.1](https://rubygems.org/gems/jekyll-fdroid/versions/0.1.1)
which is the last one supporting the old index.

## Publishing a new version

Jekyll-FDroid is distributed via [RubyGems.org](https://rubygems.org/gems/jekyll-fdroid).
To quickly sum up [their extensive guides](https://guides.rubygems.org/):

```bash
# Build gem package
gem build jekyll-fdroid.gemspec
# Push to RubyGems
gem push jekyll-fdroid-1.0.0.gem
```

## License

This program is Free Software:
You can use, study share and improve it at your will.
Specifically you can redistribute and/or modify it under the terms of the
[GNU Affero General Public License](https://www.gnu.org/licenses/agpl.html)
as published by the Free Software Foundation,
either version 3 of the License,
or (at your option) any later version.
