#
# Adapted from the MIT licensed Jekyll.LunrJsSearch.Indexer class at:
#
#   https://github.com/slashdotdash/jekyll-lunr-js-search/blob/master/lib/jekyll_lunr_js_search/indexer.rb
#
# The intent is to stay as close to that as possible, so that future patches could potentially be applied.
#

require 'fileutils'
require 'net/http'
require 'json'
require 'uri'
require 'v8'

module Jekyll
  module LunrJsSearch
    class Indexer
      # @param [Jekyll::Site]  site
      # @param [Array<App>]  packages
      # @return [Object]
      def generate(site, packages)
        @js_dir = 'js'

        ctx = V8::Context.new
        ctx.load(Indexer.path_to_asset('bower_components/lunr.js/lunr.js'))

        ctx['indexer'] = proc do |this|
          this.ref('id')
          this.field('name')
          this.field('summary')
        end

        ctx.eval('builder = new lunr.Builder')
        ctx.eval('builder.pipeline.add(lunr.trimmer, lunr.stopWordFilter)')
        ctx.eval('indexer.call(builder, builder)')

        @lunr_version = ctx.eval('lunr.version')
        @docs = {}

        Jekyll.logger.info "Lunr:", "Creating search index (lunr.js version #{@lunr_version})..."

        @site = site

        packages.each_with_index do |package, i|
          doc = {
            'id' => i,
            'packageName' => package.package_name,
            'icon' => package.icon,
            'name' => package.name,
            'summary' => package.summary
          }

          ctx['builder'].add(doc)
          @docs[i] = doc

          Jekyll.logger.debug "Lunr:", package.package_name
        end

        @index = ctx.eval('builder.build()')

        FileUtils.mkdir_p(File.join(site.dest, @js_dir))
        filename = File.join(@js_dir, 'index.json')

        total = {
          "docs" => @docs,
          "index" => @index.to_hash
        }

        filepath = File.join(site.dest, filename)
        File.open(filepath, "w") { |f| f.write(JSON.dump(total)) }
        Jekyll.logger.info "Lunr:", "Index ready (lunr.js v#{@lunr_version})"
        added_files = [filename]

        site_js = File.join(site.dest, @js_dir)
        extras = [
          'assets/fdroid-search-autocomplete.js',
          'bower_components/lunr.js/lunr.js',
          'bower_components/mustache.js/mustache.min.js',
          'bower_components/awesomplete/awesomplete.min.js',
          'bower_components/awesomplete/awesomplete.css'
        ]
        Jekyll.logger.info "Lunr:", "Added required assets to #{@js_dir}"
        extras.each do |path|
          src = Indexer.path_to_asset(path)
          Jekyll.logger.debug "Lunr:", "Copying asset from #{src} to #{site_js}"
          FileUtils.cp(src, site_js)
          added_files.push(File.join(@js_dir, File.basename(src)))
        end

        # Keep the written files from being cleaned by Jekyll
        added_files.each do |filename|
          site.static_files << SearchIndexFile.new(site, site.dest, "/", filename)
        end
      end

      def self.path_to_asset(path)
        return File.join(File.dirname(__FILE__), "../../#{path}")
      end
    end
  end
end
