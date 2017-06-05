#
# From the MIT licensed file here:
#
#   https://github.com/slashdotdash/jekyll-lunr-js-search/blob/master/lib/jekyll_lunr_js_search/javascript.rb
#

require "v8"
require "json"

class V8::Object
  def to_json
    @context['JSON']['stringify'].call(self)
  end

  def to_hash
    JSON.parse(to_json, :max_nesting => false)
  end
end