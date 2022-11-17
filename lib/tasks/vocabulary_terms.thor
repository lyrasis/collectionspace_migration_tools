# frozen_string_literal: true

require 'thor'

# tasks for listing record types for reference
class VocabularyTerms < Thor
  namespace :vt

  desc 'add', 'add new vocabulary terms from given CSV'
  option :csv, required: true, type: string
  def add
    puts CMT::RecordTypes.mappable
    exit(0)
  end
end
