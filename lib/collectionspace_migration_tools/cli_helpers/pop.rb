# frozen_string_literal: true

require "collectionspace/client"

module CollectionspaceMigrationTools
  module CliHelpers
    module Pop
      include Dry::Monads[:result]

      module_function

      def authorities
        CMT::RecordTypes.authorities.map do |str|
          CMT::Entity::Authority.from_str(str)
        end
      end

      def procedures
        CMT::RecordTypes.procedures.map do |str|
          CMT::Entity::Procedure.new(str)
        end
      end

      def relations
        CMT::RecordTypes.relations.map { |str| CMT::Entity::Relation.new(str) }
      end

      def query_and_populate(rectypes, cache_type = nil)
        rectypes.each do |rectype|
          meth = cache_type.nil? ? :populate_both_caches : "populate_#{cache_type}_cache".to_sym

          rectype.send(meth).either(
            ->(success) { puts "Done" },
            ->(failure) {
              puts "QUERY/POPULATE FAILED FOR #{rectype.to_s.upcase}\n#{failure}"
            }
          )
        end
      end

      def db_disconnect
        CMT.connection.close
        CMT.tunnel.close
      end

      def safe_db
        yield
      rescue => err
        raise err if options[:debug]
        warn err.message
        db_disconnect
        exit(1)
      else
        db_disconnect
        exit(0)
      end
    end
  end
end
