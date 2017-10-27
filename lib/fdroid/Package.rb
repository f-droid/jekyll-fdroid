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

    def <=>(other)
      self.version_code <=> other.version_code
    end

    def version_code
      @package['versionCode']
    end

    def version_name
      @package['versionName']
    end

    def to_data
      added = nil
      if @package['added'] != nil then
        added = Date.strptime("#{@package['added'] / 1000}", '%s')
      end

      {
        'added' => added,
        'anti_features' => @package['antiFeatures'],
        'apk_name' => @package['apkName'],
        'file_extension' => File.extname(@package['apkName'].to_s).strip.upcase[1..-1],
        'hash' => @package['hash'],
        'hash_type' => @package['hashType'],
        'max_sdk_version' => @package['maxSdkVersion'],
        'min_sdk_version' => @package['minSdkVersion'],
        'nativecode' => @package['nativecode'],
        'srcname' => @package['srcname'],
        'sig' => @package['sig'],
        'signer' => @package['signer'],
        'size' => @package['size'],
        'target_sdk_version' => @package['targetSdkVersion'],
        'uses_permission' => permission,
        'version_name' => version_name,
        'version_code' => version_code,
      }
    end

    def permission
      if @package['uses-permission'] == nil then
        []
      else
        @package['uses-permission'].map { |perm| Permission.new(perm).to_data }
      end
    end

    private

    def field(name)
      @app.key?(name) ? name : nil
    end
  end
end
