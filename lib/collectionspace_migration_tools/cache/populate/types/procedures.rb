# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Cache
    module Populate
      module Types
        module Procedures
          include UriCacheable

          def command
            :put_procedure
          end

          def signature(row)
            type = CMT::RecordTypes.mappable_type_to_service_path_mapping[
              row["type"]
            ]
            [type, row["id"], row[cache_type.to_s]]
          end

          def key_val(row)
            type = CMT::RecordTypes.mappable_type_to_service_path_mapping[
              row["type"]
            ]

            key = case cache_type
            when "refname"
              cache.send(:procedure_key, type, row["id"])
            when "csid"
              cache.send(:procedure_key, type, row[csid_id_field])
            end

            [key, row[cache_type.to_s]]
          end
        end
      end
    end
  end
end
