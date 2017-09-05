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

require_relative './Permission'

module FDroid
  class Package
    def initialize(package)
      @package = package
    end

    def <=> (other)
      self.version_code <=> other.version_code
    end

    def version_code
      @package['versionCode']
    end

    def to_data
      added = nil
      if @package['added'] != nil then
        added = Date.strptime("#{@package['added'] / 1000}", '%s')
      end

      {
        'version_name' => @package['versionName'],
        'version_code' => version_code,
        'added' => added,
        'apk_name' => @package['apkName'],
        'hash' => @package['hash'],
        'hash_type' => @package['hashType'],
        'min_sdk_version' => @package['minSdkVersion'],
        'max_sdk_version' => @package['maxSdkVersion'],
        'target_sdk_version' => @package['targetSdkVersion'],
        'native_code' => @package['nativecode'],
        'sig' => @package['sig'],
        'size' => @package['size'],
        'uses_permission' => permission,
      }
    end

    def permission
      if @package['uses-permission'] == nil then
        []
      else
        @package['uses-permission'].map {|perm| Permission.new(perm).to_data }
      end
    end

    private

    def field(name)
      @app.key?(name) ? name : nil
    end
  end
end