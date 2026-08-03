# frozen_string_literal: true

require "dry/monads"
require "socket"

module CollectionspaceMigrationTools
  module Database
    # Opens SSH tunnel so we can connect to database through bastion server
    class OpenTunnel
      # How long to wait for the SSH tunnel to connect (allows users to respond to trust prompt)
      TUNNEL_TIMEOUT = 30
      # How often to check whether it's connected
      TUNNEL_POLLING_INTERVAL = 0.25

      class << self
        include Dry::Monads[:result]

        # @param site_name [String]
        def call(site_name = nil)
          if CMT.config.client.db_tunnel_skip
            tunnel_obj = CMT::NoTunnel.new
            CMT.set_tunnel(tunnel_obj)
            return Success(tunnel_obj)
          end

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

          # Instead of immediately detaching the process (which steamrolls the
          # trust prompt), wait for the tunnel to come up first.
          wait_thread = Process.detach(tunnel_pid)

          unless tunnel_pid.is_a?(Integer)
            return Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
              message: "Tunnel not created"))
          end

          ready = wait_for_tunnel(wait_thread)
          return ready if ready.failure?

          tunnel_obj = CMT::Tunnel.new(tunnel_pid, tunnel_command)
          CMT.set_tunnel(tunnel_obj)
          Success(tunnel_obj)
        rescue => err
          Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
            message: err))
        end

        def wait_for_tunnel(wait_thread)
          port = CMT.config.system.db_port
          deadline = Time.now + TUNNEL_TIMEOUT

          puts "Waiting for SSH tunnel to open on port #{port}."

          until Time.now > deadline
            unless wait_thread.alive?
              return Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
                message: "SSH tunnel process exited!"))
            end

            begin
              TCPSocket.new("127.0.0.1", port).close
              return Success()
            rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT
              sleep TUNNEL_POLLING_INTERVAL
            end
          end

          Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
            message: "Timed out after #{TUNNEL_TIMEOUT}s waiting for SSH tunnel on port #{port} to open."))
        end
      end
    end
  end
end
