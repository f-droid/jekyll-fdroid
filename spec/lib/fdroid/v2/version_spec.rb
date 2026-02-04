# frozen_string_literal: true

require 'rspec'
require 'json'
require 'date'
require_relative '../../../../lib/fdroid/v2/permission'
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
  end
end
