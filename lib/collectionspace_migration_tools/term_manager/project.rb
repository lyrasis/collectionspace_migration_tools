# frozen_string_literal: true

require "logger"

module CollectionspaceMigrationTools
  module TermManager
    class Project
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:set_up_config)

      attr_reader :id

      # @param projectname [String]
      # @param instances [:all, Array[<String>]]
      # @param term_sources [:all, Array[<String>]]
      def initialize(projectname, instances: nil, term_sources: nil)
        @id = projectname
        @given_instances = instances
        @given_term_sources = term_sources
        @run_log_path = File.expand_path(config.run_log)
      end

      def config
        return @config if instance_variable_defined?(:@config)

        @config = set_up_config
        @config
      end

      def instances = @instances ||= build_instances

      def term_sources = @term_sources ||= build_term_sources

      def version_log = @version_log ||=
                          CMT::TM::VersionLog.new(config.version_log)

      def run_log = @run_log ||= Logger.new(run_log_path)

      private

      attr_reader :given_instances, :given_term_sources, :run_log_path

      def build_instances
        if given_instances
          build_given_instances
        else
          CMT::TermManager.build_instances(config.instances)
        end
      end

      def build_given_instances
        known = config.instances.keys.map(&:to_s)
        chk = given_instances.group_by { |i| known.include?(i) }

        if chk.key?(false)
          puts "\nWARNING: "\
            "The following instances are not configured for this project: "\
            "#{chk[false].join(", ")}.\n"\
            "Configured instances include: #{known.join(", ")}"
        end

        return unless chk.key?(true)

        CMT::TM.build_instances(chk[true])
      end

      def build_term_sources
        if given_term_sources
          build_given_term_sources
        else
          CMT::TermManager.build_term_sources(config_term_sources)
        end
      end

      def build_given_term_sources
        chk = given_term_sources.group_by do |i|
          config_term_sources.any? { |src| File.basename(src) == i }
        end

        if chk.key?(false)
          puts "\nWARNING: "\
            "The following term sources are not configured for this "\
            "project: #{chk[false].join(", ")}.\n"\
            "Configured instances include: "\
            "#{config_term_sources.map { |s| File.basename(s) }.join(", ")}"
        end
        return unless chk.key?(true)

        to_build = chk[true].map do |i|
          config_term_sources.select { |src| File.basename(src) == i }
        end.flatten

        CMT::TermManager.build_term_sources(to_build)
      end

      def config_term_sources
        return @config_term_sources if instance_variable_defined?(
          :@config_term_sources
        )

        [config.term_list_sources,
          config.authority_sources.keys].compact
          .flatten
      end

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
