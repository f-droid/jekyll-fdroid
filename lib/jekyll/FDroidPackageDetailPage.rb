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

	class FDroidPackageDetailPage < ReadYamlPage
		def initialize(site, base, package)
			$package = package
			@site = site
			@base = base
			@dir = "packages"
			@name = $package.at_xpath('id').content + "/index.html"

			self.process(@name)
			self.read_yaml(getLayoutDir(), 'package.html')

			getGeneralFrontMatterData
			getPackagesFrontMatterData
		end

		def getLayoutDir()
			layout_dir_override = File.join(site.source, "_layouts")
			if File.exists? File.join(layout_dir_override, "package.html")
				return layout_dir_override
			else
				return File.expand_path "../../_layouts", File.dirname(__FILE__)
			end
		end

		def getGeneralFrontMatterData
			# Hash with relation between Jekyll and XML variable name
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
			# Add information from XML to front matter
			assignments.each do |jekyll, xml|
				addGeneralFrontMatterData(jekyll, xml)
			end
			self.data["description"] = processFdroidAppLinks(self.data["description"])
			self.data["beautifulURL"] = "/packages/" + self.data["package"]
		end

		def processFdroidAppLinks(string)
			string.gsub(/fdroid\.app:([\w._]*)/, '/packages/\1')
		end

		def addGeneralFrontMatterData(jekyll, xml)
			xmlData = $package.at_xpath(xml)
			if xmlData != nil
				self.data[jekyll] = xmlData.content
			end
		end

		# Hash with relation between Jekyll and XML variable names for the package metadata
		@@jekyllToXmlPackageAssignments = {
			"added" => "added",
			"apkName" => "apkname",
			"hash" => "hash",
			"nativeCode" => "nativecode",
			"maxSDKVersion" => "maxsdkver",
			"permissions" => "permissions",
			"sdkVersion" => "sdkver",
			"sig" => "sig",
			"size" => "size",
			"srcName" => "srcname",
			"targetSdkVersion" => "targetSdkVersion",
			"version" => "version",
			"versionCode" => "versioncode",
		}

		def getPackagesFrontMatterData
			self.data["packages"] = $package.xpath('package').map { |package| getPackageFromXml(package) }
		end

		def getPackageFromXml(packageXml)
			packageInformation = Hash.new
			
			# Add information from XML to front matter
			@@jekyllToXmlPackageAssignments.each do |jekyll, xml|
				xmlData = packageXml.at_xpath(xml)
				if xmlData == nil
					next
				end

				# nativeCode and permissions can be comma separated arrays
				if ["nativeCode", "permissions"].include? jekyll
					packageInformation[jekyll] = xmlData.content.split(",")
				else
					packageInformation[jekyll] = xmlData.content
				end
			end

			return packageInformation
		end
	end
end
