# frozen_string_literal: true

require 'zeitwerk'

Zeitwerk::Loader.for_gem.setup

# Main namespace.
module CollectionspaceMigrationTools
  ::CMT = CollectionspaceMigrationTools

  class << self
    def client
      return @client if instance_variable_defined?(:@client)
      
      client = CMT::Client.call
      if client.success?
        @client = client.value!
        return @client
      end

      puts client.failure.to_s
      exit
    end
  end
end
