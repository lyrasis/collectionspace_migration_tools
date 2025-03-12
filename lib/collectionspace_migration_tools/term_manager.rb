# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    ::TM = CMT::TermManager

    module_function

    def config(project)
      TM::Project.new(project).config
    end
  end
end
