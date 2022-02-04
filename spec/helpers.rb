# frozen_string_literal: true

module Helpers
  extend self

  def valid_config
    CMT::ConfigParser.call(File.join(Bundler.root, 'spec', 'support', 'fixtures', 'config_valid.yml'))
      .value!
  end
end
