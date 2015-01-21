# capistrano-karaf

Functions to use karaf in capistrano.

## Opensshproxy
As the ssh server in karaf isn't really reliable,  i've created a custom backend for SSHKit to connect to the ssh server on the host and connect to localhost.  It will also retry commands 3 times in case of a command error.

To use the backend i recommend following configuration:

In your Capistrano config file add the following:

    ```
    require 'capistrano-karaf/backends/opensshproxy'        
    set :sshkit_backend, Capistrano_karaf::Backend::SshProxy
    ```

This configures the correct backend.  The backend is configurable with the following options:

- :karaf\_role the symbol of the class for karaf commands.  Defaults to :karaf
- :karaf\_username the username to connect to karaf.  Defaults to "smx"
- :karaf\_password the password to connect to karaf.  Defaults to "smx"
- :karaf\_port the port number of the karaf ssh server.  Defaults to 8101

For example:

    ```
    server 'esb-a-test.sensors.elex.be',
        user: 'jenkins',
        roles: [:esb, :cfengine_update]

    server 'esb-b-test.sensors.elex.be',
        user: 'jenkins',
        roles: [:esb, :cfengine_update]

    server '10.32.16.22',
        user: 'jenkins',
        roles: [:karaf]
    ```

After those changes capistrano should use the backend for the configured targets.
