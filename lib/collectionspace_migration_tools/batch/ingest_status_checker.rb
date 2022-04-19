# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batch
    class IngestStatusChecker
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)
      
      class << self
        def call(...)
          self.new(...).call
        end
      end

      # @param lister [CMT::S3::BucketLister]
      def initialize(lister:, wait:, checks:, rechecks:)
        @lister = lister
        @wait = wait
        @checks = checks
        @rechecks = rechecks
        @chk_ct = 0
        @rechk_ct = 0
      end

      def call
        size = yield(get_size)
        return Success(lister) if size == 0
        
        @last_size = size

        _chk = yield(do_checks)
        _rechk = yield(do_rechecks) unless this_size == 0

        Success(lister)
      end
      
      private

      attr_reader :lister, :wait, :checks, :rechecks, :chk_ct, :rechk_ct, :last_size, :this_size

      def do_checks
        until chk_ct == checks do
          sleep wait

          size = get_size
          break Failure(size.failue) if size.failure?

          @this_size = size.value!
          return Success() if this_size == 0
          inc_chk
          
          if maybe_done?
            return Success()
          else
            @last_size = this_size
          end
        end
        Failure("Ingest is still being processed: #{this_size} remaining")
      end

      def do_rechecks
        until rechk_ct == rechecks do
          sleep wait

          size = get_size
          break Failure(size.failue) if size.failure?

          @this_size = size.value!
          return Success() if this_size == 0

          inc_rechk

          return Failure("Ingest is still being processed: #{this_size} remaining") unless maybe_done?
        end
        Success()
      end

      def get_size
        lister.call.either(
          ->(success){ Success(lister.size) },
          ->(failure){ Failure(failure) }
        )
      end
      
      def inc_chk
        @chk_ct += 1
      end

      def inc_rechk
        @rechk_ct += 1
      end

      def maybe_done?
        this_size == last_size
      end
    end
  end
end

