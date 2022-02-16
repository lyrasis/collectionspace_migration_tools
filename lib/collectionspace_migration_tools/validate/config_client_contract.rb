# frozen_string_literal: true

require 'dry/validation'

module CollectionspaceMigrationTools
  module Validate
    class ConfigClientContract < CMT::Validate::ApplicationContract
      params do
        required(:base_uri).filled(:string)
        required(:username).filled(:string)
        required(:password).filled(:string)
        required(:page_size).filled(:integer)
        required(:redis_db_number).filled(:integer)
      end

      rule(:base_uri) do
        key.failure(%(must end with "/cspace-services")) unless value.end_with?('/cspace-services')
      end

      rule(:username) do
        unless /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i.match?(value)
          key.failure('must be a valid email address')
        end
      end
    end
  end
end
