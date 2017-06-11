# F-Droid's Jekyll Plugin
#
# Copyright (C) 2017 Peter Serwylo
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

	class FDroidSearchTemplateableAutocompleteBlock < Liquid::Block
    def self.render_template(context, template)
      context['result_item_template'] = template
      context['search_id'] = rand(1000000)

      template = Liquid::Template.parse(IO.read((File.expand_path "../../_layouts/search-autocomplete.html", File.dirname(__FILE__))))
      template.render(context)
    end

    def render(context)
      FDroidSearchTemplateableAutocompleteBlock.render_template(context, super.to_s)
		end
  end

  class FDroidSearchAutocompleteTag < Liquid::Tag
    def render(context)
      result_item_template = IO.read((File.expand_path "../../_includes/search-autocomplete-default-result-template.html", File.dirname(__FILE__)))
      FDroidSearchTemplateableAutocompleteBlock.render_template(context, result_item_template)
    end
  end
end

Liquid::Template.register_tag('fdroid_search_autocomplete', Jekyll::FDroidSearchAutocompleteTag)
Liquid::Template.register_tag('fdroid_search_autocomplete_with_template', Jekyll::FDroidSearchTemplateableAutocompleteBlock)
