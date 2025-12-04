# frozen_string_literal: true

module FDroid
  class Index
    def self.class(version)
      case version&.downcase
      when "v2"
        FDroid::V2::Index
      else
        FDroid::IndexV1
      end
    end
  end
end
