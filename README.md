# F-Droid's Jekyll Plugin

[![Gem Version](https://badge.fury.io/rb/jekyll-fdroid.svg)](https://rubygems.org/gems/jekyll-fdroid)

With this gem you can browse packages of a F-Droid repository in a Jekyll site.
Add the following configurations to your `_config.yml`:
```
gems:
  - jekyll-fdroid
fdroid-repo: https://guardianproject.info/fdroid/repo
```

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

## Dependencies

Gem "nokogiri" needs apt package "zlib1g-dev".

## License

This program is Free Software:
You can use, study share and improve it at your will.
Specifically you can redistribute and/or modify it under the terms of the
[GNU Affero General Public License](https://www.gnu.org/licenses/agpl.html)
as published by the Free Software Foundation,
either version 3 of the License,
or (at your option) any later version.
