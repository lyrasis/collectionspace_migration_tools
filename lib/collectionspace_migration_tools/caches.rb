# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Caches
    module_function

    def get_cache(type)
      cache_method = :"#{type}_cache"
      CMT.send(cache_method)
    end

    def types
      %w[csid refname]
    end
  end
end
