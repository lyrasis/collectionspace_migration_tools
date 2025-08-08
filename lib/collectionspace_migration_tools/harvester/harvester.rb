# frozen_string_literal: true

require "forwardable"

class CMT::Entity::Procedure
  extend Forwardable
  def_delegator :mapper, :service_path
end

module CollectionspaceMigrationTools
    module Harvester
      # Harvest XML from a CollectionSpace instance
      class Harvester
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:call, :harvest)
  
        class << self
          def call(rec_type:)
            new(rec_type: rec_type).call
          end
        end

        def initialize(rec_type:)
          @client = CMT::Client.call.value!
          @rec_type = rec_type
        end
  
        def call
          _entity = yield convert_to_entity
          _result = yield harvest
  
          Success()
        end

        private

        attr_reader :client, :rec_type

        def convert_to_entity
          result = CMT::RecordTypes.to_obj(rec_type)
          if result.success?
            @entity = result.value!
            Success(@entity)
          else
            Failure(CMT::Failure.new(
              context: "#{self.class.name}.#{__callee__}",
              message: "Failed to convert #{rec_type} to an entity: #{result.failure}"
            ))
          end
        end

        def entity
          @entity ||= convert_to_entity.value!
        end

        def get_record(uri)
          result = client.get uri
          Success(result)
        rescue CollectionSpace::RequestError => err
          msg = "Request failure getting record #{uri}: #{err.message}"
          Failure(CMT::Failure.new(
            context: "#{self.class.name}.#{__callee__}", message: msg
          ))
        rescue => err
          msg = "Unexpected error getting record #{uri}: #{err.message}"
          Failure(CMT::Failure.new(
            context: "#{self.class.name}.#{__callee__}", message: msg
          ))
        end

        def get_record_count
          total_results = client.count(service_path)
          Success(total_results)
        rescue CollectionSpace::RequestError => err
          msg = "Request failure getting count for #{rec_type} (#{service_path}): #{err.message}"
          Failure(CMT::Failure.new(
            context: "#{self.class.name}.#{__callee__}", message: msg
          ))
        rescue => err
          msg = "Unexpected error getting count for #{rec_type} (#{service_path}): #{err.message}"
          Failure(CMT::Failure.new(
            context: "#{self.class.name}.#{__callee__}", message: msg
          ))
        end

        def harvest
          FileUtils.mkdir_p(File.join(CMT.config.client.base_dir, rec_type))

          total_results = yield get_record_count
          harvested = 0

          puts "Harvesting #{total_results} records of type #{rec_type}..."

          client.all(service_path).each do |record|
            result = yield get_record(record["uri"])

            harvested += 1
            if harvested % 100 == 0
              puts "Harvested #{harvested} of #{total_results} records (#{harvested / total_results * 100}%)"
            end

            yield write_xml(record, result)
          end

          puts "Harvested #{total_results} records to #{File.join(CMT.config.client.base_dir, rec_type)}"

          return Success()
        end

        def service_path
          @service_path ||= begin
            if entity.respond_to?(:mapper) && entity.mapper.respond_to?(:service_path)
              entity.mapper.service_path
            elsif entity.respond_to?(:service_path)
              entity.service_path
            else
              entity.name
            end
          end
        end

        def write_xml(record, result)
          csid = record["uri"].split("/").last
          filename = File.join(CMT.config.client.base_dir, "#{rec_type}/#{csid}.xml")

          File.write(filename, result.xml.to_s)
          Success()
        rescue => err
          msg = "Unexpected error writing XML for #{csid}: #{err.message}"
          Failure(CMT::Failure.new(
            context: "#{self.class.name}.#{__callee__}", message: msg
          ))
        end
      end
    end
  end
  