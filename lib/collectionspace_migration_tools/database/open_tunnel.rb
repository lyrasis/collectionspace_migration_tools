# frozen_string_literal: true

require "dry/monads"

module CollectionspaceMigrationTools
  module Database
    # Opens SSH tunnel so we can connect to database through bastion server
    class OpenTunnel
      class << self
        include Dry::Monads[:result]

        def call
          check_tunnel = CMT.tunnel

          if check_tunnel && check_tunnel.open?
            puts "DB SSH tunnel already open. Using existing."
            Success(check_tunnel)
          else
            open_tunnel.fmap { |tunnel| tunnel }
          end
        end

        private

        def open_tunnel
          tunnel_pid = spawn(tunnel_command)
        rescue => err
          Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
            message: err))
        else
          Process.detach(tunnel_pid)

          if tunnel_pid.is_a?(Integer)
            tunnel_obj = CMT::Tunnel.new(tunnel_pid)
            CMT.tunnel = tunnel_obj
            Success(tunnel_obj)
          else
            Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
              message: "Tunnel not created"))
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
