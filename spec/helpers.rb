# frozen_string_literal: true

module CollectionspaceMigrationTools
  #  class << self
  module_function
    def config
      @config ||= Helpers.valid_config
    end

    def config=(config_object)
      @config = config_object
    end
 # end
end

module Helpers  
  module_function

  # returns valid config parsed as hash
  def valid_config
    CMT::Configuration.new(client: valid_config_path)
  end

  # returns valid config parsed as hash
  def valid_config_hash
    CMT::ConfigParser.call(valid_config_path).value!
  end

  # returns path to valid test config (core.dev)
  def valid_config_path
    File.join(Bundler.root, 'spec', 'support', 'fixtures', 'config_valid.yml')
  end

  # returns path to valid test config (core.dev)
  def invalid_config_path
    File.join(Bundler.root, 'spec', 'support', 'fixtures', 'config_invalid.yml')
  end
end
