# frozen_string_literal: true

require_relative './permission'
require_relative '../utils'

module FDroid
  module V2
    class Version
      def initialize(key, version, locale)
        @key = key
        @version = version
        @locale = locale
      end

      def <=>(other)
        self.version_code <=> other.version_code
      end

      def version_code
        @version.dig("manifest", "versionCode")
      end

      def version_name
        @version.dig("manifest", "versionName")
      end

      def to_data
        added = @version["added"]
        added = ::Date.strptime("#{added / 1000}", "%s") unless added.nil?

        {
          "added" => added,
          "anti_features" => anti_features_v1_compatible,
          "anti_features_v2" => anti_features_v2,
          "apk_name" => apk_name,
          "file_extension" => apk_name_file_extension,
          "hash" => @version.dig("file", "sha256"),
          "hash_type" => "sha256",
          "max_sdk_version" => nil,
          "min_sdk_version" => from_manifest(["usesSdk", "minSdkVersion"]),
          "nativecode" => from_manifest(["nativecode"]),
          "srcname" => strip_starting_slash(@version.dig("src", "name")),
          "sig" => nil,
          "signer" => signer,
          "size" => @version.dig("file", "size"),
          "target_sdk_version" => from_manifest(["usesSdk", "targetSdkVersion"]),
          "uses_permission" => permission,
          "uses_permission_sdk_23" => permission_sdk_23,
          "version_name" => version_name,
          "version_code" => version_code,
          "whats_new" => whats_new,
          "release_channels" => @version.dig("releaseChannels"),
        }
      end

      def anti_features_v1_compatible
        @version["antiFeatures"]&.keys
      end

      def anti_features_v2
        anti_features_data = @version.dig("antiFeatures")
        return if anti_features_data.nil?

        anti_features_data.transform_values do |v|
          if v.is_a?(Hash)
            preferred_locale = FDroid::Utils.available_locales(@locale, v)&.first
            v.dig(preferred_locale) || v.first&.at(1)
          else
            v
          end
        end
      end

      def apk_name
        strip_starting_slash(@version.dig("file", "name"))
      end

      def apk_name_file_extension
        File.extname(apk_name).strip.upcase[1..-1]
      end

      def signer
        signer_array = from_manifest(["signer", "sha256"])
        signer_array.first unless signer_array.nil?
      end

      def permission
        up = from_manifest("usesPermission")
        return [] if up.nil?

        up.map { |perm| Permission.new(perm).to_data }
      end

      def permission_sdk_23
        up = from_manifest("usesPermissionSdk23")
        return [] if up.nil?

        up.map { |perm| Permission.new(perm).to_data }
      end

      def is_beta?
        @version.dig("releaseChannels")&.include?("Beta") == true
      end

      def whats_new
        whats_new_data = @version.dig("whatsNew")
        return if whats_new_data.nil?

        preferred_locale = FDroid::Utils.available_locales(@locale, whats_new_data)&.first
        FDroid::Utils.process_package_description(whats_new_data.dig(preferred_locale) || whats_new_data.first&.at(1))
      end

      private

      def from_manifest(fields)
        @version.dig("manifest", *fields)
      end

      def strip_starting_slash(name)
        return name if name.nil?
        return name[1..-1] if name[0].eql?("/")

        name
      end
    end
  end
end
