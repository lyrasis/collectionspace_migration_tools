# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"
require "parallel"
require "smarter_csv"

module CollectionspaceMigrationTools
  module Rels
    # Handles checking nonhierarchical relation status and reporting results
    class NhrChecker
      class << self
        # @param input [Pathname] to CSV minimally containing required fields
        #   for NHR creation/identification
        # @param output [Pathname] where to write output file
        def call(...) = new(...).call
      end

      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      # @param input [Pathname] to CSV minimally containing required fields for
      #   NHR creation/identification
      # @param output [Pathname] where to write output file
      def initialize(input:, output:)
        @input = input
        @output = output
        @threads = CMT.config.system.max_threads
      end

      def call
        start_time = Time.now
        row_getter = yield CMT::Csv::FirstRowGetter.new(input)
        checker = yield CMT::Csv::FileChecker.call(input, row_getter)
        orig_headers = checker[1].headers.map(&:downcase)
        _hdrchk = yield header_check(orig_headers)
        headers = orig_headers + %w[direction subjectcsid objectcsid
          relcsid exists check_err]
        report = CSV.open(output, "wb")
        report << headers

        client = yield CMT::Client.call

        _processed = yield process(client, report, headers)

        report.close
        elap = Time.now - start_time
        puts "NHR check time: #{elap}"
        puts "INFO: Results written to: #{output}"
        Success()
      ensure
        report.close
      end

      def to_monad
        Success(self)
      end

      def to_s = "<##{self.class}:#{object_id.to_s(8)} "\
          "input: #{input}, "\
          "output: #{output}>"

      private

      attr_reader :input, :output, :threads

      def header_check(headers)
        required = %w[item1_id item1_type item2_id item2_type]
        test = required - headers
        return Success() if test.empty?

        Failure("Input CSV must include field(s): #{required.join(", ")}")
      end

      def process(client, report, headers)
        Parallel.map(
          chunks, in_threads: threads, progress: {
            format: "%t | %B | %c of %u | %a"
          }
        ) do |chunk|
          worker(chunk, client, report, headers)
        end
      rescue => err
        Failure(err)
      else
        Success()
      end

      def chunks
        SmarterCSV.process(
          input, {
            chunk_size: 1,
            convert_values_to_numeric: false,
            strings_as_keys: true
          }
        )
      end

      def worker(chunk, client, report, headers)
        chunk.each { |row| check_nhr(row, client, report, headers) }
      end

      def check_nhr(row, client, report, headers)
        nhr = CMT::Rels::Nhr.new(row, client)
        [nhr.check_dir(1, 2), nhr.check_dir(2, 1)].each do |reldir|
          report_rel_dir(row, report, headers, reldir)
        end
      end

      def report_rel_dir(row, report, headers, reldir)
        data = row.merge(reldir)
        report << data.values_at(*headers)
      end
    end
  end
end
