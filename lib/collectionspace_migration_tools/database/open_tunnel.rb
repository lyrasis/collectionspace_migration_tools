# frozen_string_literal: true

require "dry/monads"

module CollectionspaceMigrationTools
  module Database
    # Opens SSH tunnel so we can connect to database through bastion server
    class OpenTunnel
      class << self
        include Dry::Monads[:result]

        # @param site_name [String]
        def call(site_name = nil)
          tunnel_command = CMT::Database.tunnel_command(site_name)
          check_tunnel = CMT.tunnel

          if check_tunnel&.open?
            if check_tunnel&.command == tunnel_command
              puts "DB SSH tunnel already open. Using existing."
              return Success(check_tunnel)
            else
              check_tunnel.close
            end
          end

          open_tunnel(tunnel_command).fmap { |tunnel| tunnel }
        end

        private

        def open_tunnel(tunnel_command)
          tunnel_pid = spawn(tunnel_command)
          Process.detach(tunnel_pid)

          unless tunnel_pid.is_a?(Integer)
            return Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
              message: "Tunnel not created"))
          end

          tunnel_obj = CMT::Tunnel.new(tunnel_pid, tunnel_command)
          CMT.set_tunnel(tunnel_obj)
          Success(tunnel_obj)
        rescue => err
          Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
            message: err))
        end
      end
    end
  end
end
