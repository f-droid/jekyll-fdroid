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
require 'open-uri'
require 'net/http'
require 'json'
require 'zip'
require_relative './App'
require_relative './Repo'

module FDroid
  class IndexV1
    attr_reader :apps, :repo

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
          file.write(Net::HTTP.get(repo))
        end

        Zip::File.open(jar) do |zip_file|
          entry = zip_file.glob('index-v1.json').first
          @@downloaded_repos[repo] = entry.get_input_stream.read
          next @@downloaded_repos[repo]
        end
      end
    end

    def initialize(index, locale)
      @apps = index['apps'].map do |app_json|
        packages_json = index['packages'][app_json['packageName']]
        App.new(app_json, packages_json, locale)
      end

      @repo = Repo.new(index['repo'])
    end

  end
end