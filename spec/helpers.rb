# frozen_string_literal: true

module Helpers
  module_function

  def valid_config
    CMT::ConfigParser.call(File.join(Bundler.root,
                                     'spec',
                                     'support',
                                     'fixtures',
                                     'config_valid.yml'))
                     .value!
  end
end
