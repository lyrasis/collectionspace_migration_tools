# frozen_string_literal: true

require "csv"

module CollectionspaceMigrationTools
  module S3
    class ObjKeyDecoder
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          new.call(...)
        end
      end

      def initialize
      end

      # @param scope [:bucket, String] batch prefix can be passes as String
      #   to limit to objects from a particular batch
      # @param mode [:stdout, :csv]
      def call(scope: :bucket, mode: :stdout)
        list = if scope == :bucket
          yield CMT::S3::Bucket.objects
        elsif scope.is_a?(Array)
          scope
        else
          yield CMT::S3::Bucket.batch_objects(scope)
        end
        decoded = list.map { |key| CMT::Decode.to_h(key) }
        successes = decoded.select { |result| result.success? }
          .map(&:value!)
        failures = decoded.select { |result| result.failure? }
          .map(&:failure)

        case mode
        when :stdout
          successes.each do |hash|
            pp(hash)
            puts ""
          end
          failures.each { |f| puts f }
        when :csv
          path = yield write_csv(successes, failures)
          puts "Wrote decoded to #{path}"
        end

        Success()
      end

      def to_monad
        Success(self)
      end

      private

      def write_csv(successes, failures)
        headers = successes.first.keys
        now = Time.now.strftime("%F_%H_%M")
        path = File.join(
          CMT.config.client.base_dir,
          "s3_objs_decoded_#{now}.csv"
        )
        CSV.open(path, "w") do |csv|
          csv << headers
          successes.each { |success| csv << success.values }
          failures.each do |failure|
            csv << [
              failure.context.match(/\((.*)\)/)[1],
              "DECODE ERROR",
              failure.message
            ]
          end
        end
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(
          CMT::Failure.new(
            context: "#{self.class.name}.#{__callee__}", message: msg
          )
        )
      else
        Success(path)
      end
    end
  end
end
