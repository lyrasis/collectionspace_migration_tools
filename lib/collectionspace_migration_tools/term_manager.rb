# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    ::CMT::TM = CollectionspaceMigrationTools::TermManager

    module_function

    def config(project)
      @config ||= TM::Project.new(project).config
    end
    end
  end
end
