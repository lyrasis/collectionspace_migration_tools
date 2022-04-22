# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batch
    module MissingTerms
      class BatchCreator
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:call)
        
        class << self
          def call(...)
            self.new(...).call
          end
        end

        # @param batch_id [String] batch id
        def initialize(
          batch_id:,
          source_dir: CMT.config.client.base_dir,
          batch_adder: CMT::Batch::Add.new
        )
          @id = batch_id
          @source_dir = source_dir
          @batch_adder = batch_adder
        end

        def call
          paths = yield(addable_paths)
          return Success('No missing terms batches to create') if paths.empty?
          
          adds = yield(do_adds(paths))
          _fails = yield(check_results(adds))
          
          Success()
        end
        
        private

        attr_reader :id, :source_dir, :batch_adder

        def addable?(path)
          prefix = "#{id}_missing_"
          File.basename(path).start_with?(prefix)
        end

        def addable_paths
          result = Dir.new(source_dir).children
            .select{ |filename| addable?(filename) }
            .map{ |filename| "#{source_dir}/#{filename}" }
        rescue StandardError => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
        else
          Success(result)
        end

        def add_batch(path, idx)
          rectype = get_rectype(path)
          return Failure("Cannot get mappable rectype from #{path}") if rectype.nil?
          
          batch_adder.call(
            id: create_id(idx),
            csv: path,
            rectype: rectype,
            action: 'create'
          )
        end

        def check_results(results)
          failures = results.select(&:failure?)
          return Success() if failures.empty?

          failstr = failures.map{ |f| f.to_s }
            .join('; ')
          
          Failure(failstr)
        end
        
        def create_id(idx)
          "#{id}mt#{idx}"
        end

        def do_adds(paths)
          result = paths.each_with_index.map{ |path, idx| add_batch(path, idx) }
        rescue StandardError => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
        else
          Success(result)
        end

        def get_rectype(path)
          orig_rectype = File.basename(path, '.csv')
            .split('_', 3)
            .last

          return orig_rectype if CMT::RecordTypes.mappable?(orig_rectype)

          CMT::RecordTypes.alt_auth_rectype_form(orig_rectype).either(
            ->(rectype){ rectype },
            ->(failure){ nil }
            )
        end
      end
    end
  end

end
