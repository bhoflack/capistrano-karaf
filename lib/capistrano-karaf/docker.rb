require 'capistrano-karaf/core'
require 'capistrano-karaf/extended'

module Docker

  include Capistrano_Karaf

  def list_processes
    matches = []
    procs = capture(:ps, "ax")
    procs.each_line do |line|
      m = /(?<PID>\d+)[ ]*(?<TTY>[?\w\/\d]+)[ ]*(?<STATUS>[\w\+]+)[ ]*(?<TIME>\d+:\d{1,2}+) (?<COMMAND>.*)/.match(line)
      if m then
        matches.push ({ :pid      => m['PID'],
                        :tty      => m['TTY'],
                        :status   => m['STATUS'],
                        :time     => m['TIME'],
                        :command  => m['COMMAND']
                      })
      end
    end
    matches
  end

  def force_stop
    # kill all remaining karaf processes on the server
    on roles(:esb) do
      begin 
        procs = list_processes
        karaf_procs = procs.find_all { |p| p[:command].include? "karaf" }
        karaf_procs.each do |p|
          as "smx-fuse" do
            begin
              execute(:kill, p[:pid])
            rescue
            end
          end
        end
      rescue Exception => e
        puts "#{host.hostname} got exception #{e.message}"
        raise e
      end
    end
  end

  # wait_for_smx_to_start - function that blocks till all bundles are active,  and the last one is started
  def wait_for_smx_to_start
    # wait so we can ssh to the smx console
    on roles(:karaf) do
      # wait until all bundles are started and spring context is loaded"
      puts "Waiting till all bundles are started"
      wait_for_all_bundles(:timeout => 180, :sleeptime => 10) do 
        |b| ["Active", "Resolved", "Installed"].include? b[:status] 
      end
      wait_for_bundle(:timeout => 500, :sleeptime => 10) do |b|
        if b[:name] == "Apache CXF Bundle Jar"
          puts "Bundle status #{b}"
        end
        b[:name] == "Apache CXF Bundle Jar" and (b[:blueprint] == 'Started' or b[:blueprint] == 'Created')
      end
    end
  end

  # karaf_started? - verify if karaf is listening to its ssh port
  def karaf_started?
    n = `netstat -ao | grep 8101 | wc -l`
    n.to_i > 0
  end

  # block_till_karaf_started - wait till the karaf server is listening to its ssh port
  def block_till_karaf_started (args={})
    args = {:timeout => 120, :sleeptime => 1}.merge(args)
    timeout = Time.now + args[:timeout]
    until (karaf_started? || timeout < Time.now) do
      sleep args[:sleeptime]
    end

    raise "Karaf didn\' start within #{args[:timeout]} seconds." unless karaf_started?
  end

  def block_till_everything_is_started
    block_till_karaf_started
    puts "Sleeping for 20 seconds"
    sleep 20
    wait_for_smx_to_start      
  end

  def with_karaf
    if not karaf_started?
      pid = Process.spawn "/app/apache-karaf/bin/start"
      Process.detach pid
      block_till_everything_is_started
      puts "Karaf is started"
    else
      puts "Karaf is already started!"
    end

    yield
  end
end
