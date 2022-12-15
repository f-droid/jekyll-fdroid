# F-Droid's Jekyll Plugin
#
# Copyright (C) 2017 Nico Alt
# Copyright (C) 2022 FC Stegerman <flx@obfusk.net>
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

require 'loofah'
require_relative './Version'

# override the HTML elements loofah allows; be more restrictive
module Loofah::HTML5::Scrub
  OVERRIDDEN_SAFE_ELEMENTS = Set.new(
    ["a", "b", "big", "blockquote", "br", "cite", "em", "i", "small",
     "strike", "strong", "sub", "sup", "tt", "u"]
  )

  def self.allowed_element?(element_name)
    OVERRIDDEN_SAFE_ELEMENTS.include?(element_name)
  end
end

module FDroid
  class Package
    def initialize(package, versions, locale)
      # Sort versions in reverse-chronological order
      @versions = versions.map { |p| Version.new(p) }
      @package = package
      @locale = locale
      @available_locales = package.key?('localized') ? Package.available_locales(locale, package['localized']) : nil
      @is_localized = Package.is_localized(locale, @available_locales)
    end

    def package_name
      field 'packageName'
    end

    def to_s
      package_name
    end

    def icon
      localized = Package.localized_graphic_path(@available_locales, @package['localized'], 'icon')
      if localized
        "#{package_name}/#{localized}"
      elsif field('icon')
        "icons-640/#{field('icon')}"
      end
    end

    # this must exist since all entries are sorted by name,
    # it uses tildes since they sort last
    def name
      n = field('name') || Package.localized(@available_locales, @package['localized'], 'name') || '~missing name~'

      if n != nil
        n = Loofah.scrub_fragment(n, :strip).to_text()
      end

      return n
    end

    def summary
      s = field('summary') || Package.localized(@available_locales, @package['localized'], 'summary')

      if s != nil
        s = Loofah.scrub_fragment(s, :strip).to_text()
      end

      return s
    end

    def description
      desc = field('description') || Package.localized(@available_locales, @package['localized'], 'description')

      if desc != nil
        desc = Package.process_package_description(desc)
      end

      return desc
    end

    def suggested_version_code
      code = field('suggestedVersionCode')
      if code != nil
        code = Integer(code)
      end
      return code
    end

    def categories
      return field('categories')
    end

    # Generates a hash of dumb strings to be used in templates.
    # If a specific value is not present, then it will have a nil value.
    # If a value can be localized, then it will choose the most appropriate
    # translation based on @available_locales and @locale.
    # The 'versions' key is an array of Version.to_data hashes.
    # @return [Hash]
    def to_data
      liberapay = field('liberapay')
      if liberapay == nil
        liberapayID = field('liberapayID')
        if liberapayID != nil
          liberapay = "~#{liberapayID}"
        end
      end
      {
        # These fields are taken as is from the metadata. If not present, they are
        'package_name' => package_name,
        'author_email' => field('authorEmail'),
        'author_name' => field('authorName'),
        'author_website' => field('authorWebSite'),
        'translation' => field('translation'),
        'bitcoin' => field('bitcoin'),
        'litecoin' => field('litecoin'),
        'donate' => field('donate'),
        'flattrID' => field('flattrID'),
        'liberapay' => liberapay,
        'liberapayID' => field('liberapayID'),
        'openCollective' => field('openCollective'),
        'categories' => field('categories'),
        'anti_features' => field('antiFeatures'),
        'suggested_version_code' => suggested_version_code,
        'suggested_version_name' => @versions.detect { |p| p.version_code == suggested_version_code }&.version_name,
        'issue_tracker' => field('issueTracker'),
        'changelog' => field('changelog'),
        'license' => field('license'),
        'source_code' => field('sourceCode'),
        'website' => field('webSite'),
        'added' => field('added'),
        'last_updated' => field('lastUpdated'),
        'is_localized' => @is_localized,
        'whats_new' => Package.process_package_description(Package.localized(@available_locales, @package['localized'], 'whatsNew')),

        'icon' => icon,
        'title' => name,
        'summary' => summary,

        'description' => description,
        'feature_graphic' => Package.localized_graphic_path(@available_locales, @package['localized'], 'featureGraphic'),
        'phone_screenshots' => Package.localized_graphic_list_paths(@available_locales, @package['localized'], 'phoneScreenshots'),
        'seven_inch_screenshots' => Package.localized_graphic_list_paths(@available_locales, @package['localized'], 'sevenInchScreenshots'),
        'ten_inch_screenshots' => Package.localized_graphic_list_paths(@available_locales, @package['localized'], 'tenInchScreenshots'),
        'tv_screenshots' => Package.localized_graphic_list_paths(@available_locales, @package['localized'], 'tvScreenshots'),
        'wear_screenshots' => Package.localized_graphic_list_paths(@available_locales, @package['localized'], 'wearScreenshots'),

        'versions' => @versions.sort.reverse.map { |p| p.to_data },

        'beautiful_url' => "/packages/#{package_name}"
      }
    end

    # Any transformations which are required to turn the "description" into something which is
    # displayable via HTML is done here (e.g. replacing "fdroid.app:" schemes, formatting new lines,
    # etc.
    def self.process_package_description(string)
      if string == nil
        return nil
      end

      string = self.replace_fdroid_app_links(string)
      self.format_description_to_html(string)
    end

    # Finds all https://f-droid.org links that end with an Application ID, and
    # replaces them with an HTML link.
    # @param [string]  string
    # @return [string]
    def self.replace_fdroid_app_links(string)
      string.gsub(/fdroid\.app:([a-zA-Z0-9._]+)/,
                  '<a href="/packages/\1/"><tt>\1</tt></a>')
            .gsub(/([^"])(https:\/\/f-droid\.org\/[^\s?#]+\/)((?:[a-zA-Z_]+(?:\d*[a-zA-Z_]*)*)(?:\.[a-zA-Z_]+(?:\d*[a-zA-Z_]*)*)*)\/?/,
                  '\1<a href="\2\3/"><tt>\3</tt></a>')
    end

    # Ensure newlines in descriptions are preserved (converted to "<br />" tags)
    # Handles UNIX, Windows and MacOS newlines, with a one-to-one replacement
    def self.format_description_to_html(string)
      Loofah.scrub_fragment(string, :strip).to_html(:save_with => 0).gsub(/(?:\n\r?|\r\n?)/, '<br />')
    end

    # @param [string] available_locales
    # @param [string] localized
    # @param [string] field
    # @return [string]
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

    # simple test for whether this app contains localized metadata for this app
    def self.is_localized(locale, available_locales)
      return nil unless locale != nil and available_locales != nil
      return locale if locale == '_'

      available_locales.each do |l|
        if l == locale
          return l
        end
      end
      lang = locale.split(/[_-]/)[0]
      available_locales.each do |l|
        if l == lang
          return l
        end
      end
      available_locales.each do |l|
        if l.start_with?(lang)
          return l
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
    #  * Language portion matches and region matches an "alias" (e.g. zh_Hant and zh-TW).
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
      # website uses zh_Hant/zh_Hans, but zh-TW/zh-CN are common in localized data
      aliases = { 'zh' => { 'Hant' => ['TW'], 'Hans' => ['CN'] } }

      parts = desired_locale.split(/[_-]/)
      desired_lang = parts[0]
      desired_region = parts.length > 1 ? parts[1] : nil

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
          if aliases.fetch(lang, {}).fetch(desired_region, []).include?(region)
            return 2
          else
            return 3
          end
        elsif locale == 'en-US'
          return 4
        elsif lang == 'en' && region.nil?
          return 5
        elsif lang == 'en'
          return 6
        end
      end

      locales.sort do |a, b|
        measure_locale_goodness.call(a) <=> measure_locale_goodness.call(b)
      end
    end

    private

    def field(name)
      if @package.key?(name)
        value = @package[name]
        case value
        when Float then return value
        when Integer then return value
        when Array then return value.map { |i| Loofah.scrub_fragment(i, :strip).to_html(:save_with => 0) }
        else
          return Loofah.scrub_fragment(value, :strip).to_html(:save_with => 0)
        end
      end
    end
  end
end
