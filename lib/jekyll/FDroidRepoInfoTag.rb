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

require_relative '../fdroid/IndexV1'

module Jekyll

  # Used to output the repo name/timestamp used to generate this F-Droid site.
  class FDroidRepoInfoTag < Liquid::Tag

    @@repotag = ''

    def initialize(tag_name, text, tokens)
      super
    end

    def render(context)
      if @@repotag == ''
        site = context.registers[:site]
        url = site.config['fdroid-repo']
        index = FDroid::IndexV1.download(url, 'en')
        @@repotag = "#{index.repo.name} #{index.repo.date}"
      end
      return @@repotag
    end
  end
end

Liquid::Template.register_tag('fdroid_repo_info', Jekyll::FDroidRepoInfoTag)
