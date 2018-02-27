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

require 'loofah'

module FDroid
  class Repo
    def initialize(repo)
      @repo = repo
    end

    def name
      Loofah.scrub_fragment(@repo['name'], :escape).to_s
    end

    def address
      @repo['address']
    end

    def icon_url
      "#{self.address}/icons/#{@repo['icon']}"
    end

    def description
      Loofah.scrub_fragment(@repo['description'], :escape).to_s
    end

    def timestamp
      @repo['timestamp']
    end

    def date
      added = Date.strptime("#{@repo['timestamp'] / 1000}", '%s')
    end
  end
end
