# frozen_string_literal: true

require 'rspec'
require_relative '../../../../lib/fdroid/v2/permission'

module FDroid::V2
  RSpec.describe Permission do
    let(:permission) { Permission.new(permission_data) }
    let(:permission_data) do
      {
        "name" => "android.permission.INTERNET",
        "minSdkVersion" => 0,
        "maxSdkVersion" => 1,
      }
    end

    it "returns to_data" do
      expect(permission.to_data).to eq(
        {
          "permission" => "android.permission.INTERNET",
          "min_sdk" => 0,
          "max_sdk" => 1,
        }
      )
    end
  end
end
