# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class Project
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:set_up_config)

      attr_reader :id

      # @param projectname [String]
      def initialize(projectname)
        @id = projectname
      end

      def config
        return @config if instance_variable_defined?(:@config)

        @config = set_up_config
        @config
      end

      def instances = @instances ||=
                        CMT::TermManager.build_instances(config.instances)

      def term_sources = @term_sources ||=
                           CMT::TermManager.build_term_sources(
                             config_term_sources
                           )

      def version_log = @version_log ||=
                          CMT::TM::VersionLog.new(config.version_log)

      private

      def config_term_sources = [config.term_list_sources,
        config.authority_sources].compact
        .flatten

      def set_up_config
        path = yield config_path
        parsed = yield CMT::Parse::YamlConfig.call(path)
        result = yield CMT.config.add_config(:term_manager, parsed)

        result.term_manager
      end

      def config_path
        base = CMT.config.system.term_manager_config_dir
        file = Dir.new(base)
          .children
          .find { |child| child.start_with?("#{id}.") }

        return Success(File.join(base, file)) if file

        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: "Term manager config not found for #{id}"))
      end
    end
  end
end
