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

        index = FDroid::IndexV1.download(site.config["fdroid-repo"], site.active_lang || 'en_US')

        # Generate collection and detail page for every category
        site.config["app_categories"].each do |app_category|
          app_category_id = Utils.slugify(app_category)
          site.collections[app_category_id] = Collection.new(site, app_category_id)
          site.pages << FDroidCategoryDetailPage.new(site, site.source, app_category, app_category_id)
        end

        # Generate detail page for every package
        site.collections["packages"] = Collection.new(site, "packages")
        index.apps.each do |package|
          # This page needs to be created twice, once for site.pages, and once for site.collections.
          # If not, then the i18n code in jekyll-polyglot will end up processing the page twice, as
          # it iterates over all pages and all packages. The end result is a double prefix for "/en/en"
          # for any links in the page.
          # https://gitlab.com/fdroid/jekyll-fdroid/issues/38
          site.pages << FDroidPackageDetailPage.new(site, site.source, package)
          site.collections["packages"].docs << FDroidPackageDetailPage.new(site, site.source, package)

          package.categories.each do |app_category|
            app_category_id = app_category.dup
            app_category_id.sub!('&amp;', '&')
            app_category_id = Utils.slugify(app_category_id)
            if site.collections[app_category_id].nil?
              puts("Warning: App '#{package.package_name}' has unknown category '#{app_category}', will be ignored")
            else
              site.collections[app_category_id].docs << FDroidPackageDetailPage.new(site, site.source, package)
            end
          end
        end

        # Generate browsing pages
        site.includes_load_paths << (File.expand_path "../../_includes", File.dirname(__FILE__))
        site.pages << FDroidBrowsingPage.new(site, site.source)
      end
    end
  end
end
