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

module Jekyll

	class FDroidPackagesGenerator < Generator
		attr_accessor :alreadyBuilt

		safe true
		priority :highest

		def generate(site)
			# generator will only run on first build, not because of auto-regeneration
			if @alreadyBuilt != true
				@alreadyBuilt = true

				# Add plugin's SASS directory so site's list of SASS directories
				if site.config["sass"].nil? || site.config["sass"].empty?
					site.config["sass"] = Hash.new
				end
				if site.config["sass"]["load_paths"].nil? || site.config["sass"]["load_paths"].empty?
					site.config["sass"]["load_paths"] = ["_sass", (File.expand_path "../../_sass", File.dirname(__FILE__))]
				else
					site.config["sass"]["load_paths"] << (File.expand_path "../../_sass", File.dirname(__FILE__))
				end

				# Enable pagination
				if site.config["pagination"].nil? || site.config["pagination"].empty?
					site.config["pagination"] = Hash.new
				end
				site.config["pagination"]["enabled"] = true

				packages = FDroidIndex.new.getIndex(site.config["fdroid-repo"])

        Jekyll::LunrJsSearch::Indexer.new.generate(site, packages)

				# Generate detail page for every package
				site.collections["packages"] = Collection.new(site, "packages")
				packages.each do |package|
					myPage = FDroidPackageDetailPage.new(site, site.source, package)
					site.pages << myPage
					site.collections["packages"].docs << myPage
				end
				# Generate browsing pages
				site.includes_load_paths << (File.expand_path "../../_includes", File.dirname(__FILE__))
				site.pages << FDroidBrowsingPage.new(site, site.source)
			end
		end
	end
end
