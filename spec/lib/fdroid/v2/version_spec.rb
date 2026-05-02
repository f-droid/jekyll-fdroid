# frozen_string_literal: true

require 'rspec'
require 'json'
require 'date'
require_relative '../../../../lib/fdroid/Package'
require_relative '../../../../lib/fdroid/v2/permission'
require_relative '../../../../lib/fdroid/v2/uses_permission'
require_relative '../../../../lib/fdroid/v2/version'

module FDroid::V2
  RSpec.describe Version do
    let(:version) { Version.new(key, version_data, locale) }

    let (:gp_package) do
      JSON.parse(File.read("spec/assets/v2/index-v2-gp.json")).dig("packages").first
    end

    let(:key) { gp_package[1]["versions"].keys.first }
    let(:version_data) { gp_package[1]["versions"].values.first }
    let(:locale) { 'en' }

    it "returns to_data" do
      expect(version.to_data.class).to be(Hash)
    end

    describe "#uses_permission" do
      it "returns uses_permission hash" do
        expect(version.uses_permission.first.keys).to eq(["name", "min_sdk", "max_sdk"])
      end

      it "returns empty uses_permission_sdk_23" do
        expect(version.uses_permission_sdk_23).to be_empty
      end
    end

    describe "#uses_permission_sdk_23" do
      let(:pkg_name) { "org.torproject.torbrowser_alpha" }
      let(:gp_package) do
        JSON.parse(File.read("spec/assets/v2/index-v2-gp.json")).dig("packages", pkg_name)
      end

      let(:key) { gp_package["versions"].keys.first }
      let(:version_data) { gp_package["versions"].values.first }

      it "returns uses_permission_sdk_23 hash" do
        expect(version.uses_permission_sdk_23.first.keys).to eq(["name", "min_sdk", "max_sdk"])
      end
    end
  end
end
