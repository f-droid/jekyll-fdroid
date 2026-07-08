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

        index_version = site.config.dig("jekyll-fdroid", "index_version")
        fdroid_index = FDroid::Index.class(index_version)
        index = fdroid_index.download(site.config["fdroid-repo"], site.active_lang || 'en_US')

        extras = nil
        if index_version != 'v1'
          repo = index.repo
          anti_features = repo.anti_features(site.active_lang)
          categories = repo.categories(site.active_lang)
          extras = {
            "repo" => {
              "anti_features" => anti_features,
              "categories" => categories
            }
          }
        end

        category_groups = site.config["category_groups"]
        (extras ||= {})["category_groups"] = category_groups if category_groups

        app_categories = categories ? categories.keys : site.config["app_categories"]

        # Generate collection and detail page for every category
        app_categories.each do |app_category|
          app_category_id = Utils.slugify(app_category)
          site.collections[app_category_id] = Collection.new(site, app_category_id)
          site.pages << FDroidCategoryDetailPage.new(site, site.source, app_category, app_category_id, extras)
        end

        # Generate detail page for every package
        site.collections["packages"] = Collection.new(site, "packages")
        index.packages.each do |package|
          packagePage = FDroidPackageDetailPage.new(site, site.source, package, extras)
          site.pages << packagePage
          site.collections["packages"].docs << packagePage

          package.categories.each do |app_category|
            app_category_id = Utils.slugify(app_category)
            if site.collections[app_category_id].nil?
              puts("Warning: Package '#{package.package_name}' has unknown category '#{app_category}', will be ignored")
            else
              site.collections[app_category_id].docs << packagePage
            end
          end
        end

        # Generate browsing pages
        site.includes_load_paths << (File.expand_path "../../_includes", File.dirname(__FILE__))
        browsing_page = FDroidBrowsingPage.new(site, site.source, extras)
        site.pages << browsing_page

        if category_groups
          browsing_page.hook_callback = Proc.new do |hook_name, page|
            generate_category_groups_css(page, category_groups, app_categories) if hook_name == :post_render
          end
        end
      end
    end

    def generate_category_groups_css(page, category_groups, app_categories)
      grouping = {}
      empty_groups = nil
      catch_all = nil
      len = category_groups.length
      css = String.new('<style>')
      css << "\n"
      category_groups.each_with_index do |(key, value), index|
        categories = (is_hash = value.is_a?(Hash)) ? value['categories'] : value
        if (is_fallback = is_hash && value['fallback']) || !categories || categories.empty?
          (empty_groups ||= []) << index
          catch_all = index if is_fallback
        else
          order = index - len;
          css << ".g#{index} { order: #{order}; }\n"
          categories.each do |category|
            grouping[category] = order unless grouping.include?(category)
          end
        end
      end
      catch_all = empty_groups.last if catch_all.nil? && empty_groups
      ungrouped_categories = nil
      app_categories.each_with_index do |category, index|
        if (has_group = grouping.include?(category)) || catch_all
          order = has_group ? grouping[category] : catch_all - len
          css << ".c#{index} { order: #{order}; }\n" if has_group
          css << ".g#{order + len}:has(details:not([open])) ~ .c#{index} { grid-template-rows: 0fr; }\n"
        end
        (ungrouped_categories ||= []) << index unless has_group
      end
      empty_groups&.each do |index|
        css << ".g#{index} { #{index == catch_all && ungrouped_categories ? 'order: 0;' : 'display: none;'}\n"
      end
      css << '</style>'

      if (pos = page.output.index('</head>'))
        page.output.insert(pos, css)
      elsif (pos = page.output.index('<body'))
        page.output.insert(pos, "<head>#{css}</head>")
      end
    end
  end
end
