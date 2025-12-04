# frozen_string_literal: true

require 'rspec'
require 'json'
require_relative '../../../../lib/fdroid/v2/utils'

module FDroid
  module V2
    RSpec.describe Utils do
      let (:utils) { Class.new { extend Utils } }
      let(:app_pkg_metadata) do
        {
          "liberapay" => "TestLiberapay"
        }
      end

      describe "#liberapay" do
        it "returns liberapay" do
          expect(utils.liberapay(app_pkg_metadata)).to eq("TestLiberapay")
        end

        context "when fallback to liberapay_id" do
          let(:app_pkg_metadata) do
            {
              "liberapayID" => "TestLiberapayID"
            }
          end

          it "returns liberapayID formatted" do
            expect(utils.liberapay(app_pkg_metadata)).to eq("~TestLiberapayID")
          end
        end

        context "when neither is present" do
          let(:app_pkg_metadata) { {} }

          it "returns nil" do
            expect(utils.liberapay(app_pkg_metadata)).to be_nil
          end
        end
      end

      describe "#liberapay_id" do
        let(:app_pkg_metadata) do
          {
            "liberapayID" => "TestLiberapayID"
          }
        end

        it "returns liberapayID" do
          expect(utils.liberapay_id(app_pkg_metadata)).to eq("TestLiberapayID")
        end

        context "when it is not present" do
          let(:app_pkg_metadata) { {} }

          it "returns nil" do
            expect(utils.liberapay_id(app_pkg_metadata)).to be_nil
          end
        end
      end
    end
  end
end
