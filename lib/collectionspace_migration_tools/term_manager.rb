# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    ::CMT::TM = CollectionspaceMigrationTools::TermManager

    module_function

    def config(project)
      @config ||= TM::Project.new(project).config
    end

    # @param names [Array<String>]
    # @return [Array<CMT::TM::Instance>]
    def build_instances(names) = names.map do |instance, cfg|
      CMT::TM::Instance.new(instance, cfg)
    end

    # @param paths [Array<String>]
    # @return [Array<CMT::TM::TermSource>]
    def build_term_sources(paths) = paths.map do |path|
      CMT::TM::TermSource.new(path)
    end
  end
end
