# frozen_string_literal: true

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

      def anti_features
        @repo.dig("antiFeatures")
      end

      def categories
        @repo.dig("categories")
      end

      private

      def primary_language
        @primary_language ||= @repo.dig("name").keys.first
      end
    end
  end
end
