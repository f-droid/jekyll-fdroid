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
		safe true
		priority :highest

		def generate(site)
			packages = FDroidIndex.new.getIndex(site.config["fdroid-repo"] || 'https://f-droid.org/repo')
			# Generate detail page for every package
			packages.each do |package|
				myPage = FDroidPackageDetailPage.new(site, site.source, package)
				site.pages << myPage
				site.collections["apps"].docs << myPage
			end
		end
	end
end