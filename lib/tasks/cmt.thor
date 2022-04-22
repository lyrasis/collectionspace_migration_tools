# frozen_string_literal: true

require 'thor'

# tasks targeting CS XML payloads
class Cmt < Thor  
  desc 'version', 'shows CollectionspaceMigrationTools version'
  method_option aliases: 'v'
  def version
    puts "CollectionspaceMigrationTools #{CMT::VERSION}"
    exit(0)
  end
end
