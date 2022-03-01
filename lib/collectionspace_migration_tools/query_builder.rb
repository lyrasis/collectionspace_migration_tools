# frozen_string_literal: true

require 'collectionspace/client'

module CollectionspaceMigrationTools
  # Namespace for QueryBuilder service objects. Each of the QueryBuilders in this namespace
  #   has a public `query` method 
  module QueryBuilder
    ::CMT::QB = QueryBuilder

    class UnknownTypeError < StandardError; end

  end
end
