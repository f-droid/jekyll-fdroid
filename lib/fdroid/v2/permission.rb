# frozen_string_literal: true

module FDroid
  module V2
    class Permission
      def initialize(permission)
        @permission = permission.dig('name')
        @min_sdk = permission.dig('minSdkVersion')
        @max_sdk = permission.dig('maxSdkVersion')
      end

      def to_data
        {
          "permission" => @permission,
          "min_sdk" => @min_sdk,
          "max_sdk" => @max_sdk,
        }
      end
    end
  end
end
