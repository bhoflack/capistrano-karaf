require 'capistrano'

def with_karaf (params={}, &block)
  params = { :username => 'smx',
             :password => 'smx',
             :port     => 8101 }.merge(params)

  unless self[:username] == params[:username]
    set :port, params[:port]
    set :user, params[:username]
    set :password, params[:password]
    close_sessions
  end

  yield
end

def close_sessions
  sessions.values.each {|session| session.close}
  sessions.clear
end


def add_url (url, params={})
  with_karaf params do
    run "features:addurl #{url}", {:shell => false}
  end
end

def remove_url (url, params={})
  with_karaf params do
    run "features:removeurl #{url}", {:shell => false}
  end
end

def feature_install (name, params={})
  with_karaf params do
    run "features:install #{name}", {:shell => false, :pty => true}
  end
end

def feature_uninstall (name, params={})
  with_karaf params do
    run "features:uninstall #{name}", {:shell => false}
  end
end

def list_bundles (params = {})
  bundle_line_matcher = /^\[(?<BundleId>[ \d]+)\] \[(?<BundleStatus>[ \w]+)\] \[[ ]*\] \[(?<ContextStatus>[ \w]+)\] \[(?<BundleLevel> [ \d]+)\] (?<BundleName>[\w\-\:]+) \((?<BundleVersion>.+)\)/

  with_karaf params do
    run "list" do |_, _, data|
      bundles = []
      data.lines.each do |line|
        m = bundle_line_matcher.match(line)
        if m then
          bundles.push({ :id => m['BundleId'],
                         :status => m['BundleStatus'],
                         :context => m['ContextStatus'],
                         :level => m['BundleLevel'],
                         :name => m['BundleName'],
                         :version => m['BundleVersion']
                       })
        end
      end
      bundles
    end
  end
end

def started? (name, params={})
  bundle = list_bundles.find {|b| b[:name] == name}
  bundle[0][:context] == 'Started'
end

def list (params={})
  with_karaf params do
    run "features:list", {:shell => false}
  end
end


