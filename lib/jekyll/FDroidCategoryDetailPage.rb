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
  class FDroidCategoryDetailPage < ReadYamlPage
    # @param [Jekyll::Site]  site
    # @param [string]  base
    # @param [string]  app_category
    def initialize(site, base, app_category)
      @site = site
      @base = base
      @dir = 'categories'

      # Avoid special characters in URL, otherwise language support doesn't work
      app_category_url = app_category.dup
      app_category_url.sub! ' & ', '_'
      @name = "#{app_category_url}/index.html"

      self.process(@name)
      self.read_yaml(get_layout_dir, 'category-packages.html')
      self.data['app_category'] = app_category
    end

    def get_layout_dir()
      layout_dir_override = File.join(site.source, '_layouts')
      if File.exists? File.join(layout_dir_override, 'category-packages.html')
        layout_dir_override
      else
        File.expand_path '../../_layouts', File.dirname(__FILE__)
      end
    end
  end
end