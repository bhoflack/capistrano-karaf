require 'sshkit/backends/netssh'

module Capistrano_karaf
  module Backend
    class KarafCommand
      attr_reader :karaf_username, :karaf_password, :karaf_port

      def initialize
        @karaf_username = fetch :karaf_username, "smx"
        @karaf_password = fetch :karaf_password, "smx"
        @karaf_port = fetch :karaf_port, "8101"
      end

      def create(*args)
        command = args.shift.to_s.strip
        command1 = SSHKit.config.command_map[command.to_sym].split(' ')
        args1 = command1.concat(args)
        ["sshpass", "-p", karaf_password, "ssh", "-o", "NoHostAuthenticationForLocalhost=yes", "-o", "StrictHostKeyChecking=no", "#{karaf_username}@localhost", "-p", karaf_port].concat(args1)
      end
    end


    class SshProxy < SSHKit::Backend::Netssh

      @pool = SSHKit::Backend::ConnectionPool.new

      def capture(*args)
        karaf_role = fetch :karaf_role, :karaf
        if host.has_role? karaf_role

          karaf_command = KarafCommand.new
          args1 = karaf_command.create(*args)
          options = { verbosity: Logger::DEBUG }.merge(args1.extract_options!)
          
          r = _execute_command args1, options
          r.full_stdout.strip
        else
          options = { verbosity: Logger::DEBUG }.merge(args.extract_options!)
          _execute(*[*args, options]).full_stdout.strip
        end
      end

      def execute(*args)
        karaf_role = fetch :karaf_role, :karaf
        if host.has_role? karaf_role

          karaf_command = KarafCommand.new
          args1 = karaf_command.create(*args)
          options = { verbosity: Logger::DEBUG }.merge(args1.extract_options!)

          r = _execute_command args1, options
          r.success?
        else
          _execute(*args).success?
        end
      end

      private

      def _execute_command(args, options)
        r = nil
        counter = 0
        ex = nil
        begin
          counter += 1
          begin
            r = _execute *args.push(options)
            ex = nil
            break
          rescue SSHKit::Command::Failed => e
            output << SSHKit::LogMessage.new(Logger::WARN, "Got exception while running command #{args} on host #{host.hostname}: #{e}")
            ex = e
          end
        end while counter < 4
        raise ex unless ex.nil?
        r
      end
    end            
  end
end

