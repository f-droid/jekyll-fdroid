# frozen_string_literal: true

require 'rspec'
require 'json'
require 'date'
require_relative '../../../../lib/fdroid/v2/utils'
require_relative '../../../../lib/fdroid/v2/version'
require_relative '../../../../lib/fdroid/v2/package'

module FDroid::V2
  RSpec.describe Package do
    let(:package) { Package.new(pkg_name, app_json, locale) }
    let (:gp_package) do
      JSON.parse(File.read('spec/assets/v2/index-v2-gp.json')).dig("packages").first
    end
    let(:pkg_name) { gp_package[0] }
    let(:app_json) { gp_package[1] }
    let(:locale) { 'en' }

    it "creates an object of type Package" do
      expect(package.class).to be(Package)
    end

    it "returns the package name correct" do
      expect(package.package_name).to eq(pkg_name)
    end

    it "returns to_s as package_name" do
      expect(package.to_s).to eq(pkg_name)
    end

    it "returns package categories" do
      expect(package.categories).to eq(app_json.dig('metadata', 'categories'))
    end

    it "returns hash with to_data fields" do
      expect(package.to_data.class).to be(Hash)
    end

    describe "#to_data" do
      it "has support for several keys" do
        expect(package.to_data.keys).to eq([
                                             "package_name",
                                             "author_email",
                                             "author_name",
                                             "author_website",
                                             "translation",
                                             "bitcoin",
                                             "litecoin",
                                             "donate",
                                             "liberapay",
                                             "liberapayID",
                                             "openCollective",
                                             "categories",
                                             "changelog",
                                             "suggested_version_code",
                                             "suggested_version_name",
                                             "issue_tracker",
                                             "license",
                                             "source_code",
                                             "website",
                                             "added",
                                             "last_updated",
                                             "is_localized",
                                             "whats_new",
                                             "icon",
                                             "name",
                                             "title",
                                             "summary",
                                             "description",
                                             "video",
                                             "feature_graphic",
                                             "phone_screenshots",
                                             "seven_inch_screenshots",
                                             "ten_inch_screenshots",
                                             "tv_screenshots",
                                             "wear_screenshots",
                                             "versions",
                                             "beautiful_url",
                                           ])
      end
    end
  end
end
