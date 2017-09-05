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

    # @param [Jekyll::Site]  site
    # @param [string]  base
    # @param [FDfroid::App]  package
    def initialize(site, base, package)
      @site = site
      @base = base
      @dir = 'packages'
      @name = "#{package.package_name}/index.html"

      self.process(@name)
      self.read_yaml(get_layout_dir, 'package.html')
      self.data.update(package.to_data)
    end

    def get_layout_dir()
      layout_dir_override = File.join(site.source, '_layouts')
      if File.exists? File.join(layout_dir_override, 'package.html')
        layout_dir_override
      else
        File.expand_path '../../_layouts', File.dirname(__FILE__)
      end
    end
  end
end
