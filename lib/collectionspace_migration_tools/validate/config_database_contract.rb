require 'dry/validation'

module CollectionspaceMigrationTools
  module Validate
    class ConfigDatabaseContract < CMT::Validate::ApplicationContract
      params do
        required(:db_password).filled(:string)
        required(:db_name).filled(:string)
        required(:db_host).filled(:string)
        required(:bastion_user).filled(:string)
        required(:bastion_host).filled(:string)
      end

      rule(:db_host) do
        key.failure(%(must not contain "-bastion")) if value['-bastion']
      end

      rule(:bastion_host) do
        key.failure(%(must contain "-bastion")) unless value['-bastion']
      end
    end
  end
end
