# frozen_string_literal: true

require 'rspec'
require_relative '../../../../lib/fdroid/v2/index'

module FDroid
  module V2
    RSpec.describe Index do
      let(:download_index) { Index.download(gp_repo, locale) }
      let(:gp_repo) { "https://guardianproject.info/fdroid/repo" }
      let(:locale) { "en-US" }
      let (:gp_repo_data) do
        File.read('spec/assets/v2/index-v2-gp.json')
      end

      before do
        allow(Net::HTTP).to receive(:get).and_return(gp_repo_data)
        allow(File).to receive(:exist?).and_call_original
        allow(FileUtils).to receive(:touch)
      end

      it "downloads the GP repo JSON and initializes it" do
        expect(download_index.class).to be(Index)
      end

      it "has a repo" do
        expect(download_index.repo.class).to be(Repo)
      end

      it "has a list of packages" do
        expect(download_index.packages.first.class).to be(Package)
      end

      it "writes and touches anti_features.json file" do
        download_index
        expect(File).to have_received(:exist?).twice
        expect(FileUtils).to have_received(:touch)
      end
    end
  end
end
