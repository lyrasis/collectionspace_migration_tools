# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Cache
    module Populate
      module Types
        # Mixin module for cacheable types affected by using uri as record
        #  matchpoint
        module UriCacheable
          def csid_id_field
            return @csid_id_field if instance_variable_defined?(:@csid_id_field)

            case CMT.batch_config["record_matchpoint"]
            when "identifier" then "id"
            when "uri" then "uri"
            end
          end
        end
      end
    end
  end
end
