# frozen_string_literal: true

require 'thor'
require 'thor/hollaback'

# tasks targeting CS XML payloads
class Auth < Thor
  include CMT::CliHelpers
  namespace 'pop:auth'.to_sym

  class_option :debug, desc: 'Sets up debug mode', aliases: ['-d'], type: :boolean
  class_around :safe_db

  desc 'one RECTYPE', 'populate caches with refnames and csids for ONE authority record type'
  def one(rectype)
    query_and_populate(*authority_args([rectype]))
  end

  option :rectypes, :type => :array
  desc 'list --rectypes place work', 'populate caches with refnames and csids for list of authority record types'
  def list
    rectypes = options[:rectypes]
    query_and_populate(*authority_args(rectypes))
  end

  desc 'all', 'populate caches with refnames and csids for all authority record types'
  def all
    query_and_populate(*authority_args(authorities))
  end
end

