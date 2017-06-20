#
# From the MIT licensed file here:
#
#   https://github.com/slashdotdash/jekyll-lunr-js-search/blob/master/lib/jekyll_lunr_js_search/search_index_file.rb
#

module Jekyll
	module LunrJsSearch
		class SearchIndexFile < Jekyll::StaticFile
			# Override write as the index.json index file has already been created
			def write(dest)
				true
			end
		end
	end
end