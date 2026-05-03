# frozen_string_literal: true

require 'open-uri'
require 'net/http'
require 'json'
require 'fileutils'
require_relative './package'
require_relative './repo'

module FDroid
  module V2
    class Index
      attr_reader :packages, :repo, :anti_features

      @@downloaded_repos = {}

      # Download and parse an index, returning a new instance of IndexV2.
      # @param [string]  repo
      # @param [string]  locale
      # @return [FDroid::IndexV2]
      def self.download(repo, locale)
        repo = URI.parse "#{repo}/index-v2.json"
        index = download_index(repo)
        Index.new(JSON.parse(index), locale)
      end

      # Make a network request, download the index-v2.json file from the repo.
      # @param [string]  repo
      # @return [Hash]
      def self.download_index(repo)
        if @@downloaded_repos.has_key? repo
          return @@downloaded_repos[repo]
        end

        @@downloaded_repos[repo] = Net::HTTP.get(repo)
      end

      # @param [hash]   index: hash representation of parsed index-v2.json
      # @param [string] locale: language locale
      # @return [FDroid::Repo]
      def initialize(index, locale)
        @repo = Repo.new(index['repo'])
        @anti_features = @repo.repo_anti_features

        @packages = index['packages'].map do |pkg_name, app_json|
          pkg = Package.new(pkg_name, app_json, locale)

          register_package_anti_features(pkg)

          pkg
        end

        write_anti_features_data_file
      end

      private

      def register_package_anti_features(pkg)
        anti_features = pkg.anti_features
        anti_features&.each do |anti_feature, _description|
          @anti_features[anti_feature] ||= {}
          @anti_features[anti_feature]["apps"] ||= []
          @anti_features[anti_feature]["apps"] << pkg.package_name
        end
      end

      def write_anti_features_data_file
        timestamp = @repo.timestamp
        data_dir = "_data"
        Dir.mkdir(data_dir) unless File.exist?(data_dir)
        afj = File.join data_dir, "anti_features.json"
        # repo timestamp is a Java-style UNIX timestamp in milliseconds
        if not File.exist? afj or File.mtime(afj) != (timestamp / 1000)
          File.open(afj, "w") do |f|
            f.write(@anti_features.to_json)
          end
          FileUtils.touch afj, mtime: (timestamp / 1000)
        end
      end
    end
  end
end
