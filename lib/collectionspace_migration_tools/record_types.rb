# frozen_string_literal: true

module CollectionspaceMigrationTools
  module RecordTypes
    module_function

    def authority
      %w[citation concept location material organization person place taxon work]
    end
  end
end
