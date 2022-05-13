# frozen_string_literal: true

# Main namespace
module CollectionspaceMigrationTools
  class Tunnel
    attr_reader :pid

    def initialize(pid)
      @pid = pid
    end

    def close
      return unless open?
      
      result = Process.kill('HUP', pid)
      puts "Closed DB SSH tunnel" if result == 1
    end
    
    def open?
      status == :open
    end

    def status
      result = `ps -o pid -o ppid -o command`
        .split("\n")
        .map(&:strip)
        .select{ |process| process.start_with?(/#{pid} +#{Process.pid} +ssh -N -L/) }
      result.empty? ? :closed : :open
    end
  end
end
