# frozen_string_literal: true

module CollectionspaceMigrationTools
  # mixin module for mappable entities - sets :@mapper and :@status instance variables
  #
  # Classes mixing this in need to have the following methods:
  #   - name
  module Mappable
    include Dry::Monads[:result]

    def get_mapper
      CMT::Parse::RecordMapper.call(name).either(
        ->(mapper) do
          @mapper = mapper
          @status = Success(mapper)
        end,
        ->(failure) do
          @status = Failure(failure)
        end
      )
    end

    def to_monad = status
  end
end
