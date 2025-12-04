# frozen_string_literal: true

require 'rspec'
require 'json'
require 'date'
require_relative '../../../../lib/fdroid/v2/repo'

module FDroid::V2
  RSpec.describe Repo do
    let (:gp_repo_json) do
      JSON.parse(File.read('spec/assets/v2/index-v2-gp.json')).dig("repo")
    end
    let (:repo) { Repo.new(gp_repo_json) }
    let (:repo_primary_language) { gp_repo_json.dig("name").keys.first }

    it "initializes FDroid::V2::Repo correctly" do
      expect(repo.instance_variables).to eq([:@repo])
    end

    describe "#name" do
      let(:locale) { 'en-US' }

      it "returns the name based on locale" do
        expect(repo.name(locale)).to eq("Guardian Project")
      end

      context "when locale is valid but not the default" do
        let(:locale) { 'pt-BR' }

        it "returns the name based on locale" do
          expect(repo.name(locale)).to eq("Projeto Guardiao")
        end
      end

      context "when locale is not available" do
        let(:locale) { 'en-EN' }
        it "returns the name based on locale" do
          expect(repo.name(locale)).to eq(repo.name(repo_primary_language))
        end
      end
    end

    describe "#description" do
      let(:locale) { 'en-US' }
      it "returns the description based on locale" do
        expect(repo.description(locale)).to include("The official repository of The Guardian Project")
      end

      context "when locale is not available" do
        let(:locale) { 'en-EN' }
        it "returns the name based on locale" do
          expect(repo.description(locale)).to eq(repo.description(repo_primary_language))
        end
      end
    end

    describe "#icon" do
      let(:locale) { 'en-US' }

      it "returns the icon based on locale" do
        expect(repo.icon(locale)).to eq({ "name" => "/icons/guardianproject.png", "sha256" => "8ce480562d75897b85e717977b783ecaa8aadc685a7e4994b1755fa76884b01f", "size" => 36214 })
      end

      context "when locale is not available" do
        let(:locale) { 'en-EN' }
        it "returns the name based on locale" do
          expect(repo.icon(locale)).to eq(repo.icon(repo_primary_language))
        end
      end
    end

    describe "#direct access methods" do
      it "returns address" do
        expect(repo.address).to eq("https://guardianproject.info/fdroid/repo")
      end

      it "returns mirrors" do
        expect(repo.mirrors.count).to eq(7)
      end

      it "returns timestamp" do
        expect(repo.timestamp).to eq(1743835332000)
      end

      it "returns date" do
        expect(repo.date).to eq(Date.strptime("#{repo.timestamp / 1000}", '%s'))
      end

      it "returns antiFeatures" do
        expect(repo.anti_features.keys).to eq(["NonFreeComp"])
      end

      it "returns categories" do
        expect(repo.categories.keys).to eq(["Development", "Guardian Project", "Internet", "Multimedia", "Navigation", "Phone & SMS", "Security"])
      end
    end
  end
end
