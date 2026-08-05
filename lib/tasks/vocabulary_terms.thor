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
    result = CMT::VocabularyTerms.add(options[:csv])
    if result.success?
      exit(0)
    else
      if result.is_a?(Exception)
        puts result.message
        puts result.backtrace
      else
        puts result.failure
        purs result.trace
      end
      exit(1)
    end
  end

  desc "delete_all VOCAB", "delete all terms in given vocabulary machine name"
  def delete_all(vocab)
    result = CMT::VocabularyTerms::VocabClearer.call(vocabname: vocab)
    if result.success?
      exit(0)
    else
      if result.is_a?(Exception)
        puts result.message
        puts result.backtrace
      else
        puts result.failure
        purs result.trace
      end
      exit(1)
    end
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
    result = CMT::VocabularyTerms::Reporter.new(
      path: options[:outputpath],
      include_deletes: options[:include_deletes]
    ).call
    if result.success?
      exit(0)
    else
      if result.is_a?(Exception)
        puts result.message
        puts result.backtrace
      else
        puts result.failure
        purs result.trace
      end
      exit(1)
    end
  end
end
