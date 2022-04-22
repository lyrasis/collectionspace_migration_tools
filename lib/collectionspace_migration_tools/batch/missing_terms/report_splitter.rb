# frozen_string_literal: true

require 'csv'
require 'fileutils'
require 'smarter_csv'

module CollectionspaceMigrationTools
  module Batch
    module MissingTerms
      # Splits missing_terms.csv into separate CSVs for each type/subtype.
      # @todo optimize this for huge batches so that it reads/writes in chunks/parallel rather than holding
      #   all terms in memory. However, for initial go, we will assume there are not prohibitively large
      #   missing term files to process
      class ReportSplitter
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:call)

        class << self
          def call(...)
            self.new(...).call
          end
        end

        def initialize(
          batch_id:,
          target_dir: CMT.config.client.base_dir
        )
          @batch_id = batch_id
          @target_dir = target_dir
        end

        def call
          batch = yield(CMT::Batch.find(batch_id))
          term_ct = yield(batch.get('missing_terms'))
          return Success('No missing terms to split') if term_ct == 0

          batches_dir = CMT.config.client.batch_dir
          batch_dir = yield(batch.get('dir'))
          source = "#{batches_dir}/#{batch_dir}/missing_terms.csv"
          prephash = yield(prepare_by_authority(source))
          written = yield(write(prephash))
          paths = yield(check_write(written))
          vocabs_paths = yield(rewrite_vocab_terms(source))
          _vocabs_final = yield(swap_vocab_file(vocabs_paths))
          Success(paths)
        end
        
        private

        attr_reader :batch_id, :target_dir

        def check_write(written)
          result = written.select(&:failure?)
          return Success(written.map(&:value!)) if result.empty?

          Failure(result)
        end

        def prepare_by_authority(source)
          by_auth = {}
          SmarterCSV.process(source) do |rowarr|
            row = rowarr[0]
            vocab = row[:vocabulary]
            next if vocab.start_with?('vocabularies-')
            
            by_auth.key?(vocab) ? by_auth[vocab] << row[:term] : by_auth[vocab] = [row[:term]]
          end
        rescue StandardError => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
        else
          Success(by_auth)
        end

        def rewrite_vocab_terms(source)
          target = "#{source}.tmp"
          headers = CMT::Csv::BatchTermReporter.headers.first(4)

          CSV.open(target, 'wb') do |csv|
            csv << headers
            SmarterCSV.process(source) do |rowarr|
              row = rowarr[0]
              vocab = row[:vocabulary]
              next unless vocab.start_with?('vocabularies-')

              csv << row.values
            end
          end
        rescue StandardError => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
        else
          Success([target, source])
        end

        def swap_vocab_file(vocabs_paths)
          FileUtils.mv(vocabs_paths[0], vocabs_paths[1])
        rescue StandardError => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
        else
          Success()
        end
        
        def write(hash)
          result = hash.map do |vocab, terms|
            write_file(vocab, terms)
          end
        rescue StandardError => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
        else
          Success(result)
        end

        def write_file(vocab, terms)
          target = File.join(target_dir, "#{batch_id}_missing_#{vocab}.csv")
          CSV.open(target, 'wb') do |csv|
            csv << ['termdisplayname']
            terms.each{ |term| csv << [term]}
          end
        rescue StandardError => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
        else
          Success(target)
        end
      end
    end
  end
end
