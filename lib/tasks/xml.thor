# frozen_string_literal: true

require 'thor'

# tasks targeting CS XML payloads
class Xml < Thor
  namespace 'cmt:xml'.to_sym
  desc 'from_csv', 'Generate XML from CSV'
  def generate
  end


end
