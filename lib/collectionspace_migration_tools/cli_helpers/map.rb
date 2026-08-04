# frozen_string_literal: true

require "dry/monads"

module CollectionspaceMigrationTools
  module CliHelpers
    module Map
      include Dry::Monads[:result]

      module_function

      # @param str [String] path passed in as an option
      # @return
      def check_file(str)
        path = Pathname.new(File.expand_path(str))
        return Success(path) if path.file?

        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: "#{str} does not exist"))
      end
    end
  end
end
