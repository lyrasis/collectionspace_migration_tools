# frozen_string_literal: true

require "thor"

# tasks for listing record types for reference
class VocabularyTerms < Thor
  include Dry::Monads[:result]
  namespace :vt

  desc "add", "add new vocabulary terms from given CSV"
  option :csv, required: true, type: :string,
    desc: "File containing terms to load. If you have an `ingest_dir` "\
    "configured, you may just give the filename. Otherwise, give the full "\
    "to file."
  def add
    CMT::VocabularyTerms.add(options[:csv]).either(
      ->(success) { exit(0) },
      ->(failure) do
        if failure.is_a?(Exception)
          puts failure.message
          puts failure.backtrace
        else
          puts failure
        end
        exit(1)
      end
    )
  end
end
