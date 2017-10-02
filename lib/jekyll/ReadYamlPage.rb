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
#
# Found at https://github.com/ggreer/jekyll-gallery-generator/blob/master/lib/jekyll-gallery-generator.rb#L69

module Jekyll

  class ReadYamlPage < Page
    # We need do define it ourself because the templates are in the plugin's directory
    def read_yaml(base, name, opts = {})
      begin
        self.content = File.read(File.join(base.to_s, name.to_s), (site ? site.file_read_opts : {}).merge(opts))
        if content =~ /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m
          self.content = $POSTMATCH
          self.data = SafeYAML.load($1)
        end
      rescue SyntaxError => e
        Jekyll.logger.warn "YAML Exception reading #{File.join(base.to_s, name.to_s)}: #{e.message}"
      rescue Exception => e
        Jekyll.logger.warn "Error reading file #{File.join(base.to_s, name.to_s)}: #{e.message}"
      end

      self.data ||= {}
    end
  end
end
