# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Cache
    module Populate
      module Types
        module Relations
          def command
            :put_relation
          end

          def signature(row)
            [reltype(row), row["subjectcsid"], row["objectcsid"],
              row[cache_type.to_s]]
          end

          def key_val(row)
            [
              cache.send(:relation_key, reltype(row), row["subjectcsid"],
                row["objectcsid"]),
              row[cache_type.to_s]
            ]
          end

          private

          def reltype(row)
            lookup = {
              "affects" => "nhr",
              "hasBroader" => "hier"
            }
            type = lookup[row["relationshiptype"]]
            unless type
              puts "Unknown relation type in #{row}"
            end

            type
          end
        end
      end
    end
  end
end
