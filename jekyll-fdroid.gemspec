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

Gem::Specification.new do |s|
  s.name        = 'jekyll-fdroid'
  s.version     = '0.0.1'
  s.add_runtime_dependency "nokogiri"
  s.date        = '2017-01-14'
  s.summary     = "F-Droid - Free and Open Source Android App Repository"
  s.description = "Browse packages of a F-Droid repository."
  s.authors     = ["Nico Alt"]
  s.email       = 'nicoalt@posteo.org'
  s.files       = Dir['lib/**/*.rb']
  s.homepage    =
    'https://gitlab.com/fdroid/jekyll-fdroid'
  s.license       = 'AGPL-3.0'
end