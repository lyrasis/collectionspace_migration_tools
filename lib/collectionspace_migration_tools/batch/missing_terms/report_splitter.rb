# frozen_string_literal: true

require "csv"
require "fileutils"
require "smarter_csv"

module CollectionspaceMigrationTools
  module Batch
    module MissingTerms
      # Splits missing_terms.csv into separate CSVs for each type/subtype.
      # @TODO optimize this for huge batches so that it reads/writes in
      #   chunks/parallel rather than holding all terms in memory. However, for
      #   initial go, we will assume there are not prohibitively large
      #   missing term files to process
      class ReportSplitter
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:call)

        class << self
          def call(...)
            new(...).call
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
          batch = yield CMT::Batch.find(batch_id)
          term_ct = yield batch.get("missing_terms")
          return Success("No missing terms to split") if term_ct == 0

          batches_dir = CMT.config.client.batch_dir
          batch_dir = yield batch.get("dir")
          source = File.join(batches_dir, batch_dir, "missing_terms.csv")

          prephash = yield prepare_by_authority(source)
          written = yield write(prephash)
          paths = yield check_write(written)

          vocab_dir = CMT.config.client.ingest_dir || batch_dir
          _vocabs_paths = yield rewrite_vocab_terms(source, vocab_dir)
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
            next if vocab.start_with?("vocabularies-")

            if by_auth.key?(vocab)
              by_auth[vocab] << row[:term]
            else
              by_auth[vocab] = [row[:term]]
            end
          end
        rescue => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
            message: msg))
        else
          Success(by_auth)
        end

        def rewrite_vocab_terms(source, vocab_dir)
          vocab_terms = CSV.readlines(source)
            .select { |arr| arr.first == "vocabularies" }
          return Success("No vocab terms") if vocab_terms.empty?

          target = File.join(vocab_dir, "#{batch_id}_vocabulary_terms.csv")
          headers = %w[vocab term]

          CSV.open(target, "wb") do |csv|
            csv << headers
            vocab_terms.each { |arr| csv << [arr[1], arr[3]] }
          end
        rescue => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
            message: msg))
        else
          Success([target, source])
        end

        def write(hash)
          result = hash.map do |vocab, terms|
            write_file(vocab, terms)
          end
        rescue => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
            message: msg))
        else
          Success(result)
        end

        def write_file(vocab, terms)
          target = File.join(target_dir, "#{batch_id}_missing_#{vocab}.csv")
          CSV.open(target, "wb") do |csv|
            csv << ["termdisplayname"]
            terms.each { |term| csv << [term] }
          end
        rescue => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
            message: msg))
        else
          Success(target)
        end
      end
    end
  end
end
