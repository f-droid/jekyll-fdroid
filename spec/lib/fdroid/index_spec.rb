# frozen_string_literal: true

require 'rspec'
require_relative '../../../lib/fdroid/index'
require_relative '../../../lib/fdroid/IndexV1'
require_relative '../../../lib/fdroid/v2/index'

module FDroid
  RSpec.describe Index do
    let(:index_class) { FDroid::Index.class(version) }
    let(:version) { 'v1' }

    it "returns IndexV1 class" do
      expect(index_class).to be(FDroid::IndexV1)
    end

    context "when version is v2" do
      let(:version) { 'v2' }

      it "returns V2::Index class" do
        expect(index_class).to be(FDroid::V2::Index)
      end

      it "returns V2::Index class when V2" do
        expect(FDroid::Index.class('V2')).to be(FDroid::V2::Index)
      end
    end

    context "when version is somethind else" do
      let(:version) { 'vv' }

      it "returns V2::Index class" do
        expect(index_class).to be(FDroid::V2::Index)
      end
    end
  end
end
