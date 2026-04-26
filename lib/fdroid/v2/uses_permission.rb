# frozen_string_literal: true

module FDroid
  module V2
    class UsesPermission
      def initialize(uses_permission)
        @name = uses_permission.dig('name')
        @min_sdk = uses_permission.dig('minSdkVersion')
        @max_sdk = uses_permission.dig('maxSdkVersion')
      end

      def to_data
        {
          "name" => @name,
          "min_sdk" => @min_sdk,
          "max_sdk" => @max_sdk,
        }
      end
    end
  end
end
