# frozen_string_literal: true

require 'open-uri'
require 'net/http'
require 'json'
require_relative './package'
require_relative './repo'

module FDroid
  module V2
    class Index
      attr_reader :packages, :repo

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
        @packages = index['packages'].map do |pkg_name, app_json|
          Package.new(pkg_name, app_json, locale)
        end

        @repo = Repo.new(index['repo'])
      end
    end
  end
end
