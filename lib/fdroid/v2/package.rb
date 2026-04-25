# frozen_string_literal: true

require_relative './utils'
require_relative './version'
require_relative '../utils'

module FDroid
  module V2
    class Package
      include FDroid::V2::Utils

      private attr_reader :package_name, :metadata, :locale

      def initialize(package_name, app_json, locale)
        @package_name = package_name
        @metadata = app_json.dig('metadata')
        @versions = app_json.dig('versions').map { |k, v| Version.new(k, v, locale) }
        @locale = locale
      end

      def package_name
        @package_name
      end
      alias to_s package_name

      def categories
        from_metadata('categories')
      end

      def anti_features
        (suggested_version || latest_version)&.anti_features_v2
      end

      # Generates a hash of dumb strings to be used in templates.
      # @return [Hash]
      def to_data
        data = {
          'package_name' => package_name,
          'author_email' => from_metadata('authorEmail'),
          'author_name' => from_metadata('authorName'),
          'author_website' => from_metadata('authorWebSite'),
          'translation' => from_metadata('translation'),
          'bitcoin' => from_metadata('bitcoin'),
          'litecoin' => from_metadata('litecoin'),
          'donate' => from_metadata('donate')&.first,
          'liberapay' => liberapay(metadata),
          'liberapayID' => liberapay_id(metadata),
          'openCollective' => from_metadata('openCollective'),
          'categories' => from_metadata('categories'),
          'changelog' => from_metadata('changelog'),
          'suggested_version_code' => suggested_version&.version_code,
          'suggested_version_name' => suggested_version&.version_name,
          'issue_tracker' => from_metadata('issueTracker'),
          'license' => from_metadata('license'),
          'source_code' => from_metadata('sourceCode'),
          'website' => from_metadata('webSite'),
          'added' => from_metadata('added'),
          'last_updated' => from_metadata('lastUpdated'),
          'is_localized' => @locale,
          'whats_new' => suggested_version&.whats_new,
          'icon' => icon,
          'name' => name,
          'title' => name,
          'summary' => summary,
          'description' => FDroid::Utils.process_package_description(description),
          'video' => video,
          'feature_graphic' => feature_graphic,
          'phone_screenshots' => screenshots("phone"),
          'seven_inch_screenshots' => screenshots("sevenInch"),
          'ten_inch_screenshots' => screenshots("tenInch"),
          'tv_screenshots' => screenshots("tv"),
          'wear_screenshots' => screenshots("wear"),
          'versions' => ordered_versions.map { |p| p.to_data },
          'preferred_signer' => from_metadata('preferredSigner'),
          'beautiful_url' => "/packages/#{package_name}"
        }

        data['is_localized'] = nil unless @is_localized
        FDroid::Utils.sanitise(data, skip = ['description', 'whats_new'], skip_recursive = true)
      end

      private

      def icon
        icon_locale = preferred_locale("icon", @locale)
        strip_first_slash(from_metadata(["icon", icon_locale, "name"]))
      end

      def name
        p_locale = preferred_locale("name", @locale)
        from_metadata(["name", p_locale])
      end

      def summary
        p_locale = preferred_locale("summary", @locale)
        from_metadata(["summary", p_locale])
      end

      def video
        p_locale = preferred_locale("video", @locale)
        from_metadata(["video", p_locale])
      end

      def description
        p_locale = preferred_locale("description", @locale)
        from_metadata(["description", p_locale])
      end

      def feature_graphic
        p_locale = preferred_locale("featureGraphic", @locale)
        from_metadata(["featureGraphic", p_locale, "name"])
      end

      def screenshots(device)
        p_locale = preferred_locale(["screenshots", device], @locale)
        from_metadata(["screenshots", device, p_locale])&.map { |s| s.dig("name")&.gsub("/#{package_name}/", "") }
      end

      def ordered_versions
        @ordered_versions ||= @versions.sort_by.with_index do |version, index|
          [-version.version_code.to_i, index]
        end
      end

      def suggested_version
        @suggested_version ||= ordered_versions&.find { |version| !version.is_beta? }
      end

      def latest_version
        @latest_version ||= ordered_versions&.last
      end

      def from_metadata(fields)
        metadata.dig(*fields)
      end

      def preferred_locale(fields, default_locale)
        localized_data = from_metadata(fields)
        return default_locale if localized_data.nil?

        available_locales = FDroid::Utils.available_locales(default_locale, localized_data)
        @is_localized = FDroid::Package.is_localized(default_locale, available_locales) if @is_localized.nil? && available_locales
        available_locales&.first
      end

      def strip_first_slash(url)
        return url[1..-1] if url[0].eql?("/")

        url
      rescue => e
        # In case some URLs come with nil values
        url
      end
    end
  end
end
