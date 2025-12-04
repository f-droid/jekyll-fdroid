# frozen_string_literal: true

module FDroid
  module V2
    module Utils
      def liberapay(package)
        liberapay = package.dig('liberapay')
        return liberapay unless liberapay.nil?

        liberapay = liberapay_id(package)
        "~#{liberapay}" unless liberapay.nil?
      end

      def liberapay_id(package)
        package.dig('liberapayID')
      end
    end
  end
end
