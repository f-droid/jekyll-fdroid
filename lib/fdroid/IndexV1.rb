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

require 'tmpdir'
require 'fileutils'
require 'open-uri'
require 'net/http'
require 'json'
require 'set'
require 'zip'
require_relative './App'
require_relative './Repo'

module FDroid
  class IndexV1
    attr_reader :anti_features, :apps, :repo

    @@downloaded_repos = {}

    # Download and parse an index, returning a new instance of IndexV1.
    # @param [string]  repo
    # @param [string]  locale
    # @return [FDroid::IndexV1]
    def self.download(repo, locale)
      repo = URI.parse "#{repo}/index-v1.jar"
      index = download_index repo
      IndexV1.new(JSON.parse(index), locale)
    end

    # Make a network request, download the index-v1.jar file from the repo, unzip and get the contents
    # of the index-v1.json file.
    # @param [string]  repo
    # @return [Hash]
    def self.download_index(repo)
      if @@downloaded_repos.has_key? repo
        return @@downloaded_repos[repo]
      end

      Dir.mktmpdir do |dir|
        jar = File.join dir, 'index-v1.jar'
        open(jar, 'wb') do |file|
          begin
            file.write(Net::HTTP.get(repo))
          rescue Net::OpenTimeout, Net::ReadTimeout => e
            puts "Timeout (#{e}), retrying in 1 second..."
            sleep(1)
            retry
          end
        end

        Zip::File.open(jar) do |zip_file|
          entry = zip_file.glob('index-v1.json').first
          @@downloaded_repos[repo] = entry.get_input_stream.read
          next @@downloaded_repos[repo]
        end
      end
    end

    def check_for_anti_features(app_json, packages_json)
      if app_json.has_key?('antiFeatures')
        app_json['antiFeatures'].each do |anti_feature|
          if not @anti_features.has_key?(anti_feature)
            @anti_features[anti_feature] = Set.new
          end
          @anti_features[anti_feature] << app_json['packageName']
        end
      end
      packages_json.each do |package|
        if package.has_key?('antiFeatures')
          package['antiFeatures'].each do |anti_feature|
            if not anti_features.has_key?(anti_feature)
              @anti_features[anti_feature] = Set.new
            end
            @anti_features[anti_feature] << app_json['packageName']
          end
        end
      end
    end

    def write_out_anti_features(timestamp)
      @anti_features.each do |key, app_set|
        @anti_features[key] = app_set.sort
      end
      data_dir = "_data"
      Dir.mkdir(data_dir) unless File.exists?(data_dir)
      afj = File.join data_dir, "anti_features.json"
      # repo timestamp is a Java-style UNIX timestamp in milliseconds
      if not File.exists? afj or File.mtime(afj) != (timestamp / 1000)
        File.open(afj, "w") do |f|
          f.write(@anti_features.to_json)
        end
        FileUtils.touch afj, mtime: (timestamp / 1000)
      end
    end

    def initialize(index, locale)
      @anti_features = Hash.new
      @apps = index['apps'].map do |app_json|
        packages_json = index['packages'][app_json['packageName']]
        check_for_anti_features(app_json, packages_json)
        App.new(app_json, packages_json, locale)
      end
      write_out_anti_features(index['repo']['timestamp'])
      @repo = Repo.new(index['repo'])
    end
  end
end
