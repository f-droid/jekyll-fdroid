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

	class SearchForm
		def self.render_form(context, search_form_template_path, result_item_template_contents)
			context['result_item_template'] = result_item_template_contents
			context['search_id'] = rand(1000000)

			template = Liquid::Template.parse(IO.read((File.expand_path( search_form_template_path, File.dirname(__FILE__)))))
			template.render(context)
		end
	end

	# As the user types, a list of results is shown below the text input (floating above other content).
	# When an item is selected, it will navigate to that packages page.
	# Designed to be used in a sidebar widget.

	class DropDownWithTemplate < Liquid::Block
		def render(context)
			search_form_template_path = "../../_layouts/search-autocomplete.html"
			SearchForm.render_form(context, search_form_template_path, super.to_s)
		end
    end

	class DefaultDropDown < Liquid::Tag
		def render(context)
			search_form_template_path = "../../_layouts/search-autocomplete.html"

			result_item_template_path = "../../_includes/search-autocomplete-default-result-template.html"
			result_item_template = IO.read((File.expand_path(result_item_template_path, File.dirname(__FILE__))))

			SearchForm.render_form(context, search_form_template_path, result_item_template)
		end
	end

	# As the user types, a div is populated with search results.
	# Differs from DropDownAutocomplete in that once you move focus away from the text input, the results
	# are still displayed.
	# Designed for a fully fledged search form on its own page.

	# For each result result, this will render the template found between
	# the {% fdroid_search_full_with_template %}{% endfdroid_search_full_with_template %} tags.
	class FullSearchWithTemplate < Liquid::Block
		def render(context)
			search_form_template_path = "../../_layouts/search-full.html"
			SearchForm.render_form(context, search_form_template_path, super.to_s)
		end
	end

	# For each search result, this will render the contents of
	# "_includes/search-full-default-result-template.html" from this plugin.
	class DefaultFullSearch < Liquid::Tag
		def initialize(tag_name, argument, tokens)
			super
			@empty_search_id = argument.strip
		end

		def render(context)
			search_form_template_path = "../../_layouts/search-full.html"

			result_item_template_path = "../../_includes/search-full-default-result-template.html"
			result_item_template = IO.read((File.expand_path(result_item_template_path, File.dirname(__FILE__))))

			context['empty_search_id'] = @empty_search_id
			SearchForm.render_form(context, search_form_template_path, result_item_template)
		end
	end
end

Liquid::Template.register_tag('fdroid_search_autocomplete', Jekyll::DefaultDropDown)
Liquid::Template.register_tag('fdroid_search_autocomplete_with_template', Jekyll::DropDownWithTemplate)

# You can optionally specify the ID of a div where the results are to be rendered as the argument to these tags.
# Note that if you do so, it will hide all elements from this div when rendering it.
Liquid::Template.register_tag('fdroid_search_full', Jekyll::DefaultFullSearch)
Liquid::Template.register_tag('fdroid_search_full_with_template', Jekyll::FullSearchWithTemplate)
