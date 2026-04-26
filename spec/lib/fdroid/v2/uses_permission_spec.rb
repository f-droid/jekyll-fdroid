# frozen_string_literal: true

require 'rspec'
require_relative '../../../../lib/fdroid/v2/uses_permission'

module FDroid::V2
  RSpec.describe UsesPermission do
    let(:uses_permission) { UsesPermission.new(uses_permission_data) }
    let(:uses_permission_data) do
      {
        "name" => "android.permission.INTERNET",
        "minSdkVersion" => 0,
        "maxSdkVersion" => 1,
      }
    end

    it "returns to_data" do
      expect(uses_permission.to_data).to eq(
        {
          "name" => "android.permission.INTERNET",
          "min_sdk" => 0,
          "max_sdk" => 1,
        }
      )
    end
  end
end
