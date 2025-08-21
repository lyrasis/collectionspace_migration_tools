# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class AuthorityWorkRunner < VocabWorkRunner
      def type = plan["authorityType"]

      def subtype = plan["authoritySubtype"]

      def call
        finish
      end
    end
  end
end
