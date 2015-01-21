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

            args1 = ["sshpass", "-p", karaf_password, "ssh", "-o", "NoHostAuthenticationForLocalhost=yes", "#{karaf_username}@localhost", "-p", karaf_port].concat(args)
            options = { verbosity: Logger::DEBUG }.merge(args1.extract_options!)
            _execute(*[*args1, options]).full_stdout.strip
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

            args1 = ["sshpass", "-p", karaf_password, "ssh", "-o", "NoHostAuthenticationForLocalhost=yes", "#{karaf_username}@localhost", "-p", karaf_port].concat(args)
            _execute(*args1).success?
          else
            _execute(*args).success?
          end
      end
    end
  end
end
