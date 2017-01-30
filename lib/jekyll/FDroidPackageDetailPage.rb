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
			@site = site
			@base = base
			@dir = "packages"
			@name = package.at_xpath('id').content + "/index.html"

			self.process(@name)
			self.read_yaml(File.join(base, '_layouts'), 'app.html')
			self.data['title'] = package.at_xpath('name').content
			self.data['beautifulURL'] = "/packages/" + package.at_xpath('id').content
			xmlIcon = package.at_xpath('icon')
			if xmlIcon != nil
				self.data['icon'] = xmlIcon.content
			end
			self.data['package'] = package.at_xpath('id').content
			self.data['summary'] = package.at_xpath('summary').content
			self.data['description'] = package.at_xpath('desc').content
			self.data['license'] = package.at_xpath('license').content
			self.data['added'] = package.at_xpath('added').content
			self.data['lastupdated'] = package.at_xpath('lastupdated').content
		end
	end
end
