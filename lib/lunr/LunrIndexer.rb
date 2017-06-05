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
      def generate(site, packages)
        @js_dir = 'js'
        gem_lunr = File.join(File.dirname(__FILE__), "../../build/lunr.min.js")
        @lunr_path = File.exist?(gem_lunr) ? gem_lunr : File.join(@js_dir, File.basename(gem_lunr))
        raise "Could not find #{@lunr_path}" if !File.exist?(@lunr_path)

        ctx = V8::Context.new
        ctx.load(@lunr_path)
        ctx['indexer'] = proc do |this|
          this.ref('id')
          this.field('name')
          this.field('summary')
        end
        @index = ctx.eval('lunr(indexer)')
        @lunr_version = ctx.eval('lunr.version')
        @docs = {}

        Jekyll.logger.info "Lunr:", 'Creating search index...'

        @site = site
        index = []

        packages.each_with_index do |package, i|
          package_name = package['id']
          name = Indexer.content_from_xml(package, 'name')
          icon = Indexer.content_from_xml(package, 'icon')
          summary = Indexer.content_from_xml(package, 'summary')

          doc = {
              'id' => i,
              'packageName' => package_name,
              'icon' => icon,
              'name' => name,
              'summary' => summary
          }

          @index.add(doc)
          @docs[i] = doc

          Jekyll.logger.debug "Lunr:", package_name
        end

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
        # If we're using the gem, add the lunr and search JS files to the _site
        if File.expand_path(site_js) != File.dirname(@lunr_path)
          extras = Dir.glob(File.join(File.dirname(@lunr_path), "*.min.js"))
          FileUtils.cp(extras, site_js)
          extras.map! { |min| File.join(@js_dir, File.basename(min)) }
          Jekyll.logger.debug "Lunr:", "Added JavaScript to #{@js_dir}"
          added_files.push(*extras)
        end

        # Keep the written files from being cleaned by Jekyll
        added_files.each do |filename|
          site.static_files << SearchIndexFile.new(site, site.dest, "/", filename)
        end
      end

      def self.content_from_xml(xml_node, element_name)
        xml_data = xml_node.at_xpath(element_name)
        return xml_data == nil ? nil : xml_data.content
      end

    end
  end
end
