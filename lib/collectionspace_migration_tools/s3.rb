# frozen_string_literal: true

require "csv"

module CollectionspaceMigrationTools
  module S3
    module_function

    def obj_key_log_format(key)
      if key.end_with?("=")
        key.sub(/=+$/, "")
      elsif key.end_with?("%3D")
        key.sub(/(?:%3D)+$/, "")
      else
        key
      end
    end
  end
end
