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
require 'uri'
require_relative './Version'

# override the HTML elements loofah allows; be more restrictive
module Loofah::HTML5::Scrub
  OVERRIDDEN_SAFE_ELEMENTS = Set.new(
    ["a", "b", "big", "blockquote", "br", "cite", "em", "i", "small",
     "strike", "strong", "sub", "sup", "tt", "u"] + ["li", "ol", "ul"]
  )

  def self.allowed_element?(element_name)
    OVERRIDDEN_SAFE_ELEMENTS.include?(element_name)
  end
end

module Loofah::Scrubbers
  class FDroid < Loofah::Scrubber
    def initialize
      @direction = :top_down
    end

    def scrub(node)
      return CONTINUE unless (node.type == Nokogiri::XML::Node::ELEMENT_NODE) && (node.name == 'a')

      node.keys.each do |attribute|
        if attribute != 'href'
          node.delete attribute
        end
      end

      if node.keys.empty?
        node.name = '_remove'
        Strip.new.scrub(node)
        return STOP
      end

      begin
        url = URI.parse(node.attributes['href'].to_s)
        # the only official domain names used for this site, everything else redirects
        return STOP if (url.host == nil ||
                        url.host.empty? ||
                        url.host == 'f-droid.org' ||
                        url.host == 'staging.f-droid.org')
      rescue URI::Error
        # treat this URL as external
      end

      append_attribute(node, 'rel', 'external')
      append_attribute(node, 'rel', 'nofollow')
      append_attribute(node, 'rel', 'noopener')
      append_attribute(node, 'target', '_blank')
      return STOP
    end
  end
end

Loofah::Scrubbers::MAP[:fdroid] = Loofah::Scrubbers::FDroid

module FDroid
  class Package
    def initialize(package, versions, locale)
      # Sort versions in reverse-chronological order
      @versions = versions.map { |p| Version.new(p) }
      @package = package
      @locale = locale
      @available_locales = package.key?('localized') ? Utils.available_locales(locale, package['localized']) : nil
      @is_localized = Package.is_localized(locale, @available_locales)
    end

    # NB: safe (has strict checks on it and was the subject of a previous audit)
    def package_name
      @package['packageName']
    end

    def to_s
      package_name
    end

    # NB: safe (can contain '&' but must be in site.config["app_categories"])
    def categories
      @package['categories']
    end

    # Generates a hash of dumb strings to be used in templates.
    # If a specific value is not present, then it will have a nil value.
    # If a value can be localized, then it will choose the most appropriate
    # translation based on @available_locales and @locale.
    # The 'versions' key is an array of Version.to_data hashes.
    # @return [Hash]
    def to_data
      data = {
        # These fields are taken as is from the metadata. If not present, they are
        'package_name' => package_name,
        'author_email' => @package['authorEmail'],
        'author_name' => @package['authorName'],
        'author_website' => @package['authorWebSite'],
        'translation' => @package['translation'],
        'bitcoin' => @package['bitcoin'],
        'litecoin' => @package['litecoin'],
        'donate' => @package['donate'],
        'flattrID' => @package['flattrID'],
        'liberapay' => @package['liberapay'],
        'openCollective' => @package['openCollective'],
        'categories' => @package['categories'],
        'anti_features' => @package['antiFeatures'],
        'suggested_version_code' => suggested_version_code,
        'suggested_version_name' => @versions.detect { |p| p.version_code == suggested_version_code }&.version_name,
        'issue_tracker' => @package['issueTracker'],
        'changelog' => @package['changelog'],
        'license' => @package['license'],
        'source_code' => @package['sourceCode'],
        'website' => @package['webSite'],
        'added' => @package['added'],
        'last_updated' => @package['lastUpdated'],
        'is_localized' => @is_localized,
        'whats_new' => Utils.process_package_description(Package.localized(@available_locales, @package['localized'], 'whatsNew')),
        'icon' => icon,
        'title' => name,
        'summary' => summary,
        'description' => Utils.process_package_description(description),
        'video' => Package.localized(@available_locales, @package['localized'], 'video'),
        'feature_graphic' => Package.localized_graphic_path(@available_locales, @package['localized'], 'featureGraphic'),
        'phone_screenshots' => Package.localized_graphic_list_paths(@available_locales, @package['localized'], 'phoneScreenshots'),
        'seven_inch_screenshots' => Package.localized_graphic_list_paths(@available_locales, @package['localized'], 'sevenInchScreenshots'),
        'ten_inch_screenshots' => Package.localized_graphic_list_paths(@available_locales, @package['localized'], 'tenInchScreenshots'),
        'tv_screenshots' => Package.localized_graphic_list_paths(@available_locales, @package['localized'], 'tvScreenshots'),
        'wear_screenshots' => Package.localized_graphic_list_paths(@available_locales, @package['localized'], 'wearScreenshots'),
        'versions' => @versions.sort_by.with_index { |v, i| [-v.version_code.to_i, i] }.map { |p| p.to_data },
        'beautiful_url' => "/packages/#{package_name}"
      }

      # recursively sanitise data before returning, except for description and
      # whats_new, which have already passed through process_package_description
      # (and were thus scrubbed by loofah via format_description_to_html)
      return Utils.sanitise(data, skip = ['description', 'whats_new'])
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
      return nil unless locale != nil && available_locales != nil
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

    private

    def icon
      localized = Package.localized_graphic_path(@available_locales, @package['localized'], 'icon')
      if localized
        "#{package_name}/#{localized}"
      elsif @package['icon']
        "icons-640/#{@package['icon']}"
      end
    end

    # this must exist since all entries are sorted by name,
    # it uses tildes since they sort last
    def name
      @package['name'] || Package.localized(@available_locales, @package['localized'], 'name') || '~missing name~'
    end

    def summary
      @package['summary'] || Package.localized(@available_locales, @package['localized'], 'summary')
    end

    def description
      @package['description'] || Package.localized(@available_locales, @package['localized'], 'description')
    end

    def suggested_version_code
      Integer(@package['suggestedVersionCode']) rescue nil
    end
  end
end
