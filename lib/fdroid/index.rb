# frozen_string_literal: true

module FDroid
  class Index
    def self.class(version)
      case version&.downcase
      when "v1"
        FDroid::IndexV1
      else
        FDroid::V2::Index
      end
    end
  end
end
