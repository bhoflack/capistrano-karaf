# Core functionality of capistrano-karaf.
# This should only provide functions that map directly to karaf commands.

require 'sshkit'

SSHKit.config.command_map[:features_addurl] = 'features:addurl'
SSHKit.config.command_map[:features_listurl] = 'features:listurl'
SSHKit.config.command_map[:features_removeurl] = 'features:removeurl'
SSHKit.config.command_map[:features_refreshurl] = 'features:refreshurl'
SSHKit.config.command_map[:features_install] = 'features:install'
SSHKit.config.command_map[:features_uninstall] = 'features:uninstall'
SSHKit.config.command_map[:features_list] = 'features:list'
SSHKit.config.command_map[:features_info] = 'features:info'
SSHKit.config.command_map[:headers] = 'osgi:headers --force'
SSHKit.config.command_map[:list] = 'osgi:list'
SSHKit.config.command_map[:list_all] = 'osgi:list -t 0'
SSHKit.config.command_map[:list_urls] = 'osgi:list -t 0 -l'
SSHKit.config.command_map[:log_set] = 'log:set'
SSHKit.config.command_map[:stop] = 'osgi:stop'
SSHKit.config.command_map[:start] = 'osgi:start'
SSHKit.config.command_map[:uninstall] = 'osgi:uninstall --force'
SSHKit.config.command_map[:startlevel] = 'osgi:start-level'

module Capistrano_Karaf
  # Add a feature url to the karaf server
  #
  # url - the string containing the url
  # 
  # Examples
  #   add_url "mvn:com.melexis.esb/eventstore-feature/#{eventStoreVersion}/xml/features"
  #   # => nil
  #
  # Returns nothing
  def add_url (url)
    execute(:features_addurl, url)
  end

  # Remove a feature url from the karaf server
  #
  # url - the string containing the url
  # 
  # Examples
  #   remove_url "mvn:repository/eventstore-feature/1.0.0/xml/features"
  #   # => nil
  #
  # Returns nothing
  def remove_url (url)
    execute(:features_removeurl, url)
  end

  # Refresh the urls containing the feature repositories on the karaf server 
  #
  # Examples
  #   features_refreshurl
  #   # => nil
  #
  # Returns nothing
  def features_refreshurl
    execute(:features_refreshurl)
  end

  # Install a feature on the karaf server
  #
  # name - the string containing the feature name
  #
  # Examples
  #   feature_install "hello"
  #   # => nil
  #
  # Returns nothing
  def feature_install (name)
    execute(:features_install, name)
  end

  # Uninstall a feature on the karaf server
  #
  # name - the string containing the feature name
  # version - the optional string containing the version number
  #
  # Examples
  #   feature_uninstall "hello" "2.19.0"
  #   # => nil
  #
  # Returns nothing
  def feature_uninstall(name, version=nil)
    
    # Keep track of the bundles that are part of the feature
    feature_bundle_urls = feature_bundles(name, version).collect {|b| b[:url]}

    if version.nil? then
      execute(:features_uninstall, "#{name}")
    else
      execute(:features_uninstall, "#{name}/#{version}")
    end
    
    # Verify all bundles have been uninstalled and remove the bundle if not
    list_bundle_locations.each do |installed_bundle|
      if feature_bundle_urls.include? installed_bundle[:url] then
        uninstall installed_bundle[:id]
      end
    end
  end

  # Set the log level on the karaf server
  #
  # level - the string containing the level
  #
  # Examples
  #   log_set "debug"
  #   # => nil
  #
  # Returns nothing
  def log_set (level)
    execute(:log_set, level)
  end

  # Set the start level on the karaf server
  #
  # level - the string containing the level
  #
  # Examples
  #   startlevel_set 60
  #   # => nil
  #
  # Returns nothing
  def startlevel_set (level)
    execute(:startlevel, level)
  end

  def startlevel
    r = capture(:startlevel)
    m = r.match(/Level (\d+)/)
    if m then
      m[0].to_i
    else
      raise 'Invalid response from startlevel'
    end
  end


  # Start a bundle with the specified bundleId on the karaf server
  #
  # bundleId - a number containing the id of the bundle
  #
  # Examples
  #   start 100
  #   # => nil
  #
  # Returns nothing
  def start (bundleId)
    execute(:start, bundleId)
  end

  # Stop a bundle with the specified bundleId on the karaf server
  #
  # bundleId - a number containing the id of the bundle
  #
  # Examples
  #   stop(100)
  #   # => nil
  #
  # Returns nothing
  def stop (bundleId)
    execute(:stop, bundleId)
  end

  # Uninstall a bundle with the specified bundleId from the karaf server
  #
  # bundleId - a number containing the id of the bundle
  #
  # Examples
  #   start 100
  #   # => nil
  #
  # Returns nothing
  def uninstall (bundleId)
    execute(:uninstall, bundleId)
  end

  # List all feature urls on the karaf server
  #
  # Examples
  #   list_urls
  #   # => [{:status => "Installed", :groupID => "repository", :artifactID => "repository", :version => "1.0.0"}]
  #
  # Returns a list of hashmaps containing all feature repositories
  def list_urls
    url_line_matcher = 
        %r{ (?<status> \w+){0}
            (?<groupID> [\d\w\.\-]+){0}
            (?<artifactID> [\w\.\-]+){0}
            (?<version> [\w\.\-]+){0} 

            \s*\g<status>\s*mvn\:\g<groupID>\/\g<artifactID>\/\g<version>.*
          }x

    data = capture(:features_listurl)
    matcher_to_hash(url_line_matcher, data)
  end

  # List all features on the karaf server
  #
  # Examples
  #   list_features
  #   # => [{:status => "Installed", :name => "camel-core", :repository => "repository", :version => "1.0.0"}]
  #
  # Returns a list of hashmaps containing all available features
  def list_features
    feature_line_matcher = 
        %r{ (?<status> \w+){0}
            (?<version> [\d\w\-\.]+){0}
            (?<name> [\w\-\.\:]+){0}
            (?<repository> [\w\-\:\.]+){0}

            ^\[\s*\g<status>\s*\]\s\[\s*\g<version>\s*\]\s*\g<name>\s*\g<repository>
          }x

    data = capture(:features_list)
    matcher_to_hash(feature_line_matcher, data)
  end

  # List all bundles on the karaf server
  #
  # Examples
  #   list_bundles
  #   # => [{:id => "10", :status => "INSTALLED", :blueprint => "", :context => "", :level => "60", :name => "camel-core", :version => "1.0.0"}]
  #
  # Returns a list of hashmaps containing the installed bundles
  def list_bundles
    bundle_line_matcher = 
        %r{ (?<id> \d+){0}
            (?<status> \w+){0}
            (?<blueprint> \w*){0}
            (?<context> \w*){0}
            (?<level> \d+){0}
            (?<name> [\w\s\.\-\:]+){0}
            (?<version> .+){0}

            ^\[\s*\g<id>\]\s\[\s*\g<status>\s*\]\s\[\s*\g<blueprint>\s*\]\s\[\s*\g<context>\s*\]\s\[\s*\g<level>\s*\]\s\g<name>\s\(\g<version>\)
          }x

    fragments_matcher = /\s*Fragments: ([\d\s]+)\s*/
    
    data = capture(:list)

    fragments = []
    bundles = []

    data.lines.each do |line|
      m1 = bundle_line_matcher.match line
      m2 = fragments_matcher.match line

      if m1 then
        bundles.push(m1)
      elsif m2 then
        fragment_bundles = m2[1].split /\s+/
        fragment_bundles.each {|fb| fragments.push fb}
      end
    end

    bundles1 = bundles.collect {|m| Hash[m.names.collect {|k| k.to_sym }.zip(m.captures)]}
    bundles1.collect do |b| 
      b[:fragment] = fragments.include? b[:id]
      b
    end
  end

  # List all bundles on the karaf server
  #
  # Examples
  #   list_bundles
  #   # => [{:id => "10", :status => "INSTALLED", :blueprint => "", :context => "", :level => "60", :name => "camel-core", :version => "1.0.0"}]
  #
  # Returns a list of hashmaps containing the installed bundles
  def list_bundles
    bundle_line_matcher = 
        %r{ (?<id> \d+){0}
            (?<status> \w+){0}
            (?<blueprint> \w*){0}
            (?<context> \w*){0}
            (?<level> \d+){0}
            (?<name> [\w\s\.\-\:]+){0}
            (?<version> .+){0}

            ^\[\s*\g<id>\]\s\[\s*\g<status>\s*\]\s\[\s*\g<blueprint>\s*\]\s\[\s*\g<context>\s*\]\s\[\s*\g<level>\s*\]\s\g<name>\s\(\g<version>\)
          }x

    fragments_matcher = /\s*Fragments: ([\d\s]+)\s*/
    
    data = capture(:list)

    fragments = []
    bundles = []

    data.lines.each do |line|
      m1 = bundle_line_matcher.match line
      m2 = fragments_matcher.match line

      if m1 then
        bundles.push(m1)
      elsif m2 then
        fragment_bundles = m2[1].split /\s+/
        fragment_bundles.each {|fb| fragments.push fb}
      end
    end

    bundles1 = bundles.collect {|m| Hash[m.names.collect {|k| k.to_sym }.zip(m.captures)]}
    bundles1.collect do |b| 
      b[:fragment] = fragments.include? b[:id]
      b
    end
  end

  # List bundle locations
  #
  # Examples
  #   list_bundle_locations
  #   # => [{:id => "10", :status => "INSTALLED", :blueprint => "", :context => "", :level => "60", :url => "mvn:org.springframework/spring-webmvc/3.0.5.RELEASE"}]
  #
  # Returns a list of hashmaps containing the installed bundles and their url
  def list_bundle_locations
    bundle_line_matcher = 
        %r{ (?<id> \d+){0}
            (?<status> \w+){0}
            (?<blueprint> \w*){0}
            (?<context> \w*){0}
            (?<level> \d+){0}
            (?<url> [\w:\.\/\-]+){0}

            ^\[\s*\g<id>\]\s\[\s*\g<status>\s*\]\s\[\s*\g<blueprint>\s*\]\s\[\s*\g<context>\s*\]\s\[\s*\g<level>\s*\]\s\g<url>
          }x
    
    data = capture(:list_all)
    matcher_to_hash(bundle_line_matcher, data)
  end


  # Get the headers for a bundle
  #
  # bundleId - A number containing the bundle id
  #
  # Examples
  #   headers 10
  #   # => "..."
  #
  # Returns the string containing the headers information for the bundle.
  def headers (bundle)
    data = capture(:headers, bundle)
    extract_bundle_headers(data)
  end

  def list_headers
    data = capture(:headers)
    data.collect {|h| extract_bundles_from_feature(h)}
  end

  # List all bundles provided by a feature
  #
  # name - A string containing the name of the feature
  # version - A string containing the version of the feature
  # 
  # Examples
  #   feature_bundles "camel-core" "2.18"
  #   # => [{:groupId => "org.apache.camel", :artifactId => "camel-core", :version => "2.18"}]
  #
  # Returns a list containing the hashes with the bundle information
  def feature_bundles(name, version)
    data = capture(:features_info, "#{name} #{version}")
    extract_bundles_from_feature(data)
  end

  private

  def matcher_to_hash (matcher,data)
    breaklist = []
    data.lines.each do |line|
      m = matcher.match(line)
      breaklist.push(m) unless m.nil?
    end
    breaklist.collect {|m| Hash[m.names.collect {|n| n.to_sym}.zip(m.captures)]}
  end

  def extract_bundles_from_feature (data)
    bundles = []
    data.lines.each do |l|
      m = l.match(/mvn:(?<GroupId>[\w\.]+)\/(?<ArtifactId>[-\w\.]+)\/(?<Version>[-\d\w\.]+)/)
      if m then 
        bundles.push({ :groupId 	=> m['GroupId'],
                       :artifactId	=> m['ArtifactId'],
                       :version	        => m['Version'],
                       :url             => m[0]})
      end
    end
    bundles
  end

  def extract_bundle_headers (hdrs)
    re = /(.+) = (.+)/
    header =  {}
    lines = hdrs.lines
    lines.map {|l| m = l.match(re); if m then header[m[1].strip!] = m[2] end}
    
    m = lines[2].match(/\w+ \(([\d+])\)/)
    if m then
      header['Bundle-Number'] = m[1].to_i
    end

    header
  end
end
