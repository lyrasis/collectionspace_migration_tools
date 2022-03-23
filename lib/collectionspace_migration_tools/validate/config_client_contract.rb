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
        required(:cs_version).filled(:string)
        required(:profile).filled(:string)
        required(:profile_version).filled(:string)
        required(:base_dir).filled(:string)
        required(:mapper_dir).filled(:string)
        required(:xml_dir).filled(:string)
        required(:redis_db_number).filled(:integer)
        optional(:batch_config_path).maybe(:string)
        required(:csv_delimiter).filled(:string)
      end

      rule(:base_dir) do
        full = File.expand_path(value)
        unless Dir.exist?(full)
          key.failure("#{full} does not exist")
        end
      end
      
      rule(:base_uri) do
        key.failure(%(must end with "/cspace-services")) unless value.end_with?('/cspace-services')
      end

      rule(:batch_config_path) do
        if value        
          full = File.expand_path(value)
          unless File.exist?(full)
            key.failure("#{full} does not exist")
          end
        end
      end

      rule(:cs_version) do
        unless /^\d+_\d+$/.match(value)
          key.failure('must follow pattern: number underscore number')
        end
      end

      rule(:profile) do
        ok = %w[anthro bonsai botgarden core fcart herbarium lhmc materials publicart]
        unless ok.any?(value)
          key.failure("must be one of: #{ok.join(', ')}")
        end
      end

      rule(:profile_version) do
        unless /^\d+-\d+-\d+$/.match(value)
          key.failure('must follow pattern: number hyphen number hyphen number')
        end
      end

      rule(:username) do
        unless /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i.match?(value)
          key.failure('must be a valid email address')
        end
      end
    end
  end
end
