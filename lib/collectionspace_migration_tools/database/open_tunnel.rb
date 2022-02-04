# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  module Database
    # Opens SSH tunnel so we can connect to database through bastion server
    class OpenTunnel
      class << self
        include Dry::Monads[:result]

        def call
          open_tunnel.fmap do |tunnel|
            tunnel
          end
        end
        
        private

        def open_tunnel
          tunnel = fork{ exec tunnel_command }
        rescue StandardError => err
          Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: err))
        else
          
          Process.detach(tunnel)

          if tunnel.is_a?(Integer)
            Success(tunnel)
          else
            Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: 'Tunnel not created'))
          end
        end

        def tunnel_command
          port = CMT.config.database.port
          db_host = CMT.config.database.db_host
          user = CMT.config.database.bastion_user
          host = CMT.config.database.bastion_host
          
          %(ssh -N -L #{port}:#{db_host}:#{port} #{user}@#{host})
        end
      end
    end
  end
end

