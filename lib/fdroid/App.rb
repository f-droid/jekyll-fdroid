# F-Droid's Jekyll Plugin
#
# Copyright (C) 2017 Nico Alt
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require_relative './Package'

module FDroid
  class App
    def initialize(app, packages, locale)
      # Sort packages in reverse-chronological order
      @packages = packages.map { |p| Package.new(p) }
      @app = app
      @locale = locale
      @available_locales = app.key?('localized') ? App.available_locales(locale, app['localized']) : nil
    end

    def package_name
      field 'packageName'
    end

    def to_s
      package_name
    end

    def icon
      localized = App.localized_graphic_path(@available_locales, @app['localized'], 'icon')
      if localized
        "#{package_name}/#{localized}"
      else
        "icons-640/#{field('icon')}"
      end
    end

    def name
      App.localized(@available_locales, @app['localized'], 'name') || field('name')
    end

    def summary
      App.localized(@available_locales, @app['localized'], 'summary')
    end

    def suggested_version_code
      code = field('suggestedVersionCode')
      if code != nil
        code = Integer(code)
      end
      return code
    end


    # Generates a hash of dumb strings to be used in templates.
    # If a specific value is not present, then it will have a nil value.
    # If a value can be localized, then it will choose the most appropriate
    # translation based on @available_locales and @locale.
    # The 'packages' key is an array of Package.to_data hashes.
    # @return [Hash]
    def to_data
      localized_description = App.localized(@available_locales, @app['localized'], 'description')
      if localized_description != nil
        localized_description = App.process_app_description(localized_description)
      end

      {
          # These fields are taken as is from the metadata. If not present, they are
          'package_name' => package_name,
          'author_email' => field('authorEmail'),
          'author_name' => field('authorName'),
          'author_website' => field('authorWebSite'),
          'bitcoin' => field('bitcoin'),
          'donate' => field('donate'),
          'flattr' => field('flattr'),
          'categories' => field('categories'),
          'anti_features' => field('anti_features'),
          'suggested_version_code' => suggested_version_code,
          'suggested_version_name' => @packages.detect { |p| p.version_code == suggested_version_code }&.version_name,
          'issue_tracker' => field('issueTracker'),
          'changelog' => field('changelog'),
          'license' => field('license'),
          'source_code' => field('sourceCode'),
          'website' => field('webSite'),
          'added' => field('added'),
          'last_updated' => field('lastUpdated'),
          'whats_new' => App.process_app_description(App.localized(@available_locales, @app['localized'], 'whatsNew')),

          'icon' => icon,
          'title' => name,
          'summary' => summary,

          'description' => localized_description,
          'feature_graphic' => App.localized_graphic_path(@available_locales, @app['localized'], 'featureGraphic'),
          'phone_screenshots' => App.localized_graphic_list_paths(@available_locales, @app['localized'], 'phoneScreenshots'),
          'seven_inch_screenshots' => App.localized_graphic_list_paths(@available_locales, @app['localized'], 'sevenInchScreenshots'),

          'packages' => @packages.sort.reverse.map { |p| p.to_data },

          'beautiful_url' => "/packages/#{package_name}"
      }
    end

    # Any transformations which are required to turn the "description" into something which is
    # displayable via HTML is done here (e.g. replacing "fdroid.app:" schemes, formatting new lines,
    # etc.
    def self.process_app_description(string)
      if string == nil
        return nil
      end

      string = self.replace_fdroid_app_links(string)
      self.format_description_to_html(string)
    end

    # Finds all "fdroid.app:" schemes in a particular string, and replaces with "/packages/".
    # @param [string]  string
    # @return [string]
    def self.replace_fdroid_app_links(string)
      string.gsub /fdroid\.app:([\w._]*)/, '/packages/\1'
    end

    # Ensure double newlines "\n\n" are converted to "<br />" tags.
    def self.format_description_to_html(string)
      string
        .gsub("\n\n", '<br />')
        .gsub(/\r?\n/, ' ')
    end

    # TODO: URLs need to be prefixed with "locale/key/value", e.g. "en_US/featureGraphic/featureGraphic.png"
    def self.localized(available_locales, localized, field)
      return nil unless available_locales != nil

      available_locales.each do |l|
        if localized[l].key?(field)
          return localized[l][field]
        end
      end

      return nil
    end
    
    # Prefixes the result with "chosen_locale/" before returning.
    # @see localized
    def self.localized_graphic_path(available_locales, localized, field)
      return nil unless available_locales != nil
      
      available_locales.each do |l|
        if localized[l].key?(field)
          return "#{l}/#{localized[l][field]}"
        end
      end
      
      return nil
    end
    
    # Similar to localized_graphic_path, but prefixes each item in the resulting array
    # with "chosen_locale/field/".
    # @see localized
    # @see localized_graphic_path
    def self.localized_graphic_list_paths(available_locales, localized, field)
      return nil unless available_locales != nil
      
      available_locales.each do |l|
        if localized[l].key?(field)
          return localized[l][field].map { |val| "#{l}/#{field}/#{val}" }
        end
      end
      
      return nil
    end

    # Given the desired_locale, searches through the list of localized_data entries
    # and finds those with keys which match either:
    #  * The desired locale exactly
    #  * The same language as the desired locale (but different region)
    #  * Any English language (so if the desired language is not there it will suffice)
    #
    # These will be sorted in order of preference:
    #  * Exact matches (language and region)
    #  * Language portion matches but region is absent/doesn't match.
    #  * en-US
    #  * en
    #  * en-*
    #
    # It is intentionally liberal in searching for either "_" or "-" to separate language
    # and region, because they both mean (in different context) to split langugae on the
    # left, and region on the right, and it is cheap to do so.
    #
    # @param [string]  desired_locale
    # @param [Hash]  localized_data
    # @return [Array]
    def self.available_locales(desired_locale, localized_data)
      parts = desired_locale.split(/[_-]/)
      desired_lang = parts[0]

      locales = localized_data.keys.select do |available_locale|
        parts = available_locale.split(/[_-]/)
        available_lang = parts[0]
        available_lang == desired_lang || available_lang == 'en'
      end

      measure_locale_goodness = lambda do |locale|
        parts = locale.split(/[_-]/)
        lang = parts[0]
        region = parts.length > 1 ? parts[1] : nil
        if locale == desired_locale
          return 1
        elsif lang == desired_lang
          return 2
        elsif locale == 'en-US'
          return 3
        elsif lang == 'en' && region.nil?
          return 4
        elsif lang == 'en'
          return 5
        end
      end

      locales.sort do |a, b|
        measure_locale_goodness.call(a) <=> measure_locale_goodness.call(b)
      end
    end

    private

    def field(name)
      @app.key?(name) ? @app[name] : nil
    end
  end
end
