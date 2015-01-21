require 'sshkit/backends/netssh'

module Capistrano_karaf
  module Backend
    class SshProxy < SSHKit::Backend::Netssh

      @pool = SSHKit::Backend::ConnectionPool.new

      def capture(*args)
          karaf_role = fetch :karaf_role, :karaf
          if host.has_role? karaf_role
            
            karaf_username = fetch :karaf_username, "smx"
            karaf_password = fetch :karaf_password, "smx"
            karaf_port = fetch :karaf_port, "8101"

            args1 = ["sshpass", "-p", karaf_password, "ssh", "-o", "NoHostAuthenticationForLocalhost=yes", "-o", "StrictHostKeyChecking=no", "#{karaf_username}@localhost", "-p", karaf_port].concat(args)
            options = { verbosity: Logger::DEBUG }.merge(args1.extract_options!)

            r = nil
            counter = 0
            ex = nil
            begin
                counter += 1
                begin
                    r = _execute(*[*args1, options])
                    ex = nil
                    break
                rescue SSHKit::Command::Failed => e
                    output << SSHKit::LogMessage.new(Logger::WARN, "Got exception while running command #{args1} on host #{host.hostname}")
                    ex = e
                end
            end while counter < 4

            raise ex unless ex.nil?
            r.full_stdout.strip
          else
            options = { verbosity: Logger::DEBUG }.merge(args.extract_options!)
            _execute(*[*args, options]).full_stdout.strip
          end
      end

      def execute(*args)
          karaf_role = fetch :karaf_role, :karaf
          if host.has_role? karaf_role

            karaf_username = fetch :karaf_username, "smx"
            karaf_password = fetch :karaf_password, "smx"
            karaf_port = fetch :karaf_port, "8101"

            args1 = ["sshpass", "-p", karaf_password, "ssh", "-o", "NoHostAuthenticationForLocalhost=yes", "-o", "StrictHostKeyChecking=no", "#{karaf_username}@localhost", "-p", karaf_port].concat(args)
            r = nil
            counter = 0
            ex = nil
            begin
                counter += 1
                begin
                    r = _execute(*args1)
                    ex = nil
                    break
                rescue SSHKit::Command::Failed => e
                    output << SSHKit::LogMessage.new(Logger::WARN, "Got exception while running command #{args1} on host #{host.hostname}")
                    ex = e
                end
            end while counter < 4
            
            raise ex unless ex.nil?            
            r.success?
          else
            _execute(*args).success?
          end
      end
    end
  end
end
