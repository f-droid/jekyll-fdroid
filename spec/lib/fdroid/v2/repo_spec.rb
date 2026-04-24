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
    let (:repo_anti_features) { gp_repo_json.dig("antiFeatures") }

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
    end

    describe "#antiFeatures" do
      let(:locale) { 'en-US' }
      it "returns the anti-features based on locale" do
        expect(repo.anti_features(locale)).to eq(
          {
            "NonFreeComp" =>
            {
              "description" => "This app includes non-free components or software libraries.",
              "icon" =>
              {
                "name" => "/icons/NonFreeComp.png",
                "sha256" => "fdeb1b35495caee5e4c2a289679c978201ad46ab7627a30e501a8b5d4f295fbb",
                "size" => 897
              },
              "name" => "Non-Free Components"
            }
          }
        )
      end

      it "returns all repo antiFeatures" do
        expect(repo.repo_anti_features.class).to be(Hash)
        expect(repo.repo_anti_features).to eq(repo_anti_features)
      end

      context "when locale is not available" do
        let(:locale) { 'en-EN' }
        it "returns the name based on locale" do
          expect(repo.anti_features(locale)).to eq(repo.anti_features(repo_primary_language))
        end
      end
    end

    describe "#categories" do
      let(:locale) { 'en-US' }
      it "returns the categories based on locale" do
        expect(repo.categories(locale)).to eq(
          {
            "Development" =>
            {
              "name" => "Development"
            },
            "Guardian Project" =>
            {
              "name" => "Guardian Project"
            },
            "Internet" =>
            {
              "name" => "Internet"
            },
            "Multimedia" =>
            {
              "name" => "Multimedia"
            },
            "Navigation" =>
            {
              "name" => "Navigation"
            },
            "Phone & SMS" =>
            {
              "name" => "Phone &amp; SMS"
            },
            "Security" =>
            {
              "name" => "Security"
            }
          }
        )
      end

      context "when locale is not available" do
        let(:locale) { 'en-EN' }
        it "returns the name based on locale" do
          expect(repo.categories(locale)).to eq(repo.categories(repo_primary_language))
        end
      end
    end
  end
end
