# frozen_string_literal: true

require "thor"

# tasks for listing record types for reference
class VocabularyTerms < Thor
  include CMT::CliHelpers
  include Dry::Monads[:result]

  namespace :vt

  desc "add", "add new vocabulary terms from given CSV"
  option :csv, required: true, type: :string,
    desc: "File containing terms to load. If you have an `ingest_dir` "\
    "configured, you may just give the filename. Otherwise, give the full "\
    "to file."
  def add
    report_result(CMT::VocabularyTerms.add(options[:csv]))
  end

  desc "delete_all VOCAB", "delete all terms in given vocabulary machine name"
  def delete_all(vocab)
    report_result(CMT::VocabularyTerms::VocabClearer.call(vocabname: vocab))
  end

  desc "write", "write CSV containing all vocabulary term data for the "\
    "active client instance"
  option :outputpath,
    type: :string,
    aliases: "-o",
    required: true,
    desc: "Path where result will be written. Should be a .csv"
  option :include_deletes,
    type: :boolean,
    aliases: "-d",
    default: false,
    desc: "Whether to include soft-deleted vocabulary terms in the output"
  def write
    report_result(
      CMT::VocabularyTerms::Reporter.new(
        path: options[:outputpath],
        include_deletes: options[:include_deletes]
      ).call
    )
  end
end
