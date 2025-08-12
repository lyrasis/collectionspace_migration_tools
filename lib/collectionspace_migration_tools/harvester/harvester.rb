# frozen_string_literal: true

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
          @rec_type = rec_type
          @target_dir = File.join(CMT.config.client.base_dir, "xml", rec_type)
        end

        def call
          @client = yield CMT::Client.call
          @entity = yield CMT::RecordTypes.to_obj(rec_type)
          @service_path = entity.service_path

          result = yield harvest

          Success(result)
        end

        private

        attr_reader :client, :rec_type, :entity, :service_path, :target_dir

        def get_record(uri)
          result = client.get(uri)
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
          FileUtils.mkdir_p(target_dir)

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

          return Success("Harvested #{total_results} records to #{target_dir}")
        end

        def write_xml(record, result)
          csid = record["uri"].split("/").last
          filename = File.join(target_dir, "#{csid}.xml")

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
