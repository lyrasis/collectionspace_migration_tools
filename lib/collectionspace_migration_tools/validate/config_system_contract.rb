# frozen_string_literal: true

require 'dry/validation'

module CollectionspaceMigrationTools
  module Validate
    class ConfigSystemContract < CMT::Validate::ApplicationContract
      params do
        required(:csv_chunk_size).filled(:integer)
        required(:max_threads).filled(:integer)
      end
    end
  end
end
