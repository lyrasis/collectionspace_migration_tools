# frozen_string_literal: true

require 'thor'

# tasks for listing record types for reference
class VocabularyTerms < Thor
  include Dry::Monads[:result]
  namespace :vt

  desc 'add', 'add new vocabulary terms from given CSV'
  option :csv, required: true, type: :string
  def add
    CMT::VocabularyTerms.add(options[:csv]).either(
      ->(success){ exit(0) },
      ->(failure) do
        if failure.is_a?(Exception)
          puts failure.message
          puts failure.backtrace
        else
          puts failure.to_s
        end
        exit(1)
      end
    )
  end
end
