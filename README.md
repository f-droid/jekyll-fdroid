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

To add a search input which lets the user search all packages, use the following tags in your page.
The first renders a default list item for each search result:

```
{{ fdroid_search_autocomplete }}
```

And this allows for a custom [Mustache.js](https://github.com/janl/mustache.js) template for each search result:

```
{{ fdroid_search_autocomplete_with_template }}
Mustache.js template goes in here, and has access
to the following tags:
* {{ name }}
* {{ summary }}
* {{ icon }}
* {{ packageName }}
{{ endfdroid_search_autocomplete_with_template }}
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
