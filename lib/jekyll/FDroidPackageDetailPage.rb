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

	class FDroidPackageDetailPage < Page
		def initialize(site, base, package)
			$package = package
			@site = site
			@base = base
			@dir = "packages"
			@name = $package.at_xpath('id').content + "/index.html"

			self.process(@name)
			self.read_yaml(File.join(base, '_layouts'), 'app.html')
			getFrontMatterData
		end

		def getFrontMatterData
			assignments = Hash.new
			assignments = {
				"added" => "added",
				"antifeatures" => "antifeatures",
				"bitcoin" => "bitcoin",
				"categories" => "categories",
				"changelog" => "changelog",
				"description" => "desc",
				"donate" => "donate",
				"flattr" => "flattr",
				"icon" => "icon",
				"issueTracker" => "tracker",
				"lastUpdated" => "lastupdated",
				"license" => "license",
				"suggestedVersionCode" => "marketvercode",
				"suggestedVersion" => "marketversion",
				"package" => "id",
				"sourceCode" => "source",
				"summary" => "summary",
				"title" => "name",
				"webSite" => "web"
				}
			assignments.each do |jekyll, xml|
				addFrontMatterData(jekyll, xml)
			end
			self.data["beautifulURL"] = "/packages/" + self.data["package"]
		end

		def addFrontMatterData(jekyll, xml)
			data = $package.at_xpath(xml)
			if data != nil
				self.data[jekyll] = data.content
			end
		end
	end
end
