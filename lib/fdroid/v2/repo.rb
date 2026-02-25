# frozen_string_literal: true

require_relative '../utils'

module FDroid
  module V2
    class Repo
      def initialize(repo)
        @repo = repo
      end

      def name(language = primary_language)
        @repo.dig("name", language) || @repo.dig("name", primary_language)
      end

      def description(language = primary_language)
        @repo.dig("description", language) || @repo.dig("description", primary_language)
      end

      def icon(language = primary_language)
        @repo.dig("icon", language) || @repo.dig("icon", primary_language)
      end

      def address
        @repo.dig("address")
      end

      def mirrors
        @repo.dig("mirrors")
      end

      def timestamp
        @repo.dig("timestamp")
      end

      def date
        Date.strptime("#{timestamp / 1000}", '%s')
      end

      def anti_features(language = primary_language)
        get_localized(@repo.dig("antiFeatures"), language)
      end

      def categories(language = primary_language)
        get_localized(@repo.dig("categories"), language)
      end

      private

      def primary_language
        @primary_language ||= @repo.dig("name").keys.first
      end

      def get_localized(data, language)
        data&.transform_values do |item|
          item&.transform_values do |v|
            if v.is_a?(Hash)
              preferred_locale = FDroid::Utils.available_locales(language, v)&.first
              FDroid::Utils.sanitise(v.dig(preferred_locale || primary_language) || v.first&.at(1))
            else
              v
            end
          end
        end
      end
    end
  end
end
