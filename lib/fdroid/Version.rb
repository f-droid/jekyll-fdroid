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
  class Version
    def initialize(version)
      @version = version
    end

    def <=>(other)
      self.version_code <=> other.version_code
    end

    def version_code
      @version['versionCode']
    end

    def version_name
      @version['versionName']
    end

    def to_data
      added = nil
      if @version['added'] != nil then
        added = Date.strptime("#{@version['added'] / 1000}", '%s')
      end

      {
        'added' => added,
        'anti_features' => @version['antiFeatures'],
        'apk_name' => @version['apkName'],
        'file_extension' => File.extname(@version['apkName'].to_s).strip.upcase[1..-1],
        'hash' => @version['hash'],
        'hash_type' => @version['hashType'],
        'max_sdk_version' => @version['maxSdkVersion'],
        'min_sdk_version' => @version['minSdkVersion'],
        'nativecode' => @version['nativecode'],
        'srcname' => @version['srcname'],
        'sig' => @version['sig'],
        'signer' => @version['signer'],
        'size' => @version['size'],
        'target_sdk_version' => @version['targetSdkVersion'],
        'uses_permission' => permission,
        'version_name' => version_name,
        'version_code' => version_code,
      }
    end

    def permission
      if @version['uses-permission'] == nil then
        []
      else
        @version['uses-permission'].map { |perm| Permission.new(perm).to_data }
      end
    end

    private

    def field(name)
      @app.key?(name) ? name : nil
    end
  end
end
