# Functions that build on capistrano-karaf/core to provide extra functionality
require 'capistrano-karaf/core'

module Capistrano_Karaf

  # Remove all feature repositories with a given groupID and artifactID
  #
  # groupID - a string containing the groupID
  # artifactID - a string containing the artifactID
  # 
  # Examples
  #   remove_artifact_urls("repository", "blaat")
  #   # => nil
  #
  # Returns nothing
  def remove_artifact_urls (groupID, artifactID)
    urlsToRemove=list_urls.select {|url| url['groupID'] == groupID && url['artifactID'] == artifactID}	
    urlsToRemove.each do |url|   	
      remove_url "mvn:#{url["groupID"]}/#{url["artifactID"]}/#{url["version"]}/xml/features"
    end
  end

  # Remove a feature in a safe way
  #
  # This function verifies if the feature is installed before uninstalling it.  This 
  # way it tries to avoid an exception on the karaf server.
  #
  # name - a string containing the feature name
  # 
  # Examples
  #   feature_uninstall_safe "test"
  #   # => nil
  #
  # Returns nothing  
  def feature_uninstall_safe (name)
    feature_uninstall name unless !feature_installed? name
  end

  # Verify if a bundle is a fragment bundle
  #
  # bundleId - a number containing the bundleId
  # 
  # Examples
  #   fragment_bundle? 101
  #   # => false
  #
  # Returns a boolean
  def fragment_bundle? (bundleId)
    headers(bundleId).lines.any? {|l| l.match('^Fragment-Host.*')}
  end

  # Wait till all bundle return true for the specified predicate ( or the timeout is exceeded )
  #
  # pred - a block that can be used as predicate
  #
  # Optional parameters:
  # :timeout - a number containing the timeout in seconds ( defaults to 60 )
  # :sleeptime - a number containing the timeout between tries in seconds ( defaults to 5 )
  # 
  # Examples
  #   wait_for_all_bundles {|b| b[:context] == "STARTED"}
  #   # => nil
  #
  # Returns nothing
  def wait_for_all_bundles (args={}, &pred)
    args = {:timeout => 60, :sleeptime => 5}.merge(args)
    timeout = Time.now + args[:timeout]
    
    until Time.now > timeout or list_bundles.all? { |b| pred.call b} 
      puts "Some bundles are still failing the predicate"
      sleep args[:sleeptime]
    end
  end

  # Wait till the predicate passes for a bundle
  #
  # pred - a block that can be used as predicate
  #
  # Optional parameters:
  # :timeout - a number containing the timeout in seconds ( defaults to 60 )
  # :sleeptime - a number containing the timeout between tries in seconds ( defaults to 5 )
  # 
  # Examples
  #   wait_for_all_bundle {|b| b[:context] == "STARTED"}
  #   # => nil
  #
  # Returns nothing
  def wait_for_bundle (args={}, &pred)
    args = {:timeout => 60, :sleeptime => 5}.merge(args)
    timeout = Time.now + args[:timeout]
    
    while Time.now < timeout and list_bundles.none? { |b| pred.call b} 
      puts "Bundle not yet started"
      sleep args[:sleeptime]
    end
  end

  # Verify if a feature is installed
  #
  # name - a string containing the name of the feature
  # 
  # Examples
  #   feature_installed? "camel-core"
  #   # => true
  #
  # Returns true if the feature is installed
  def feature_installed? (name)
    feature = list_features.find {|f| f['name']==name}
    feature['status'] == 'installed' unless feature.nil?
  end

  # Verify if a the bundle context is started
  #
  # name - a string containing the name of the bundle
  # 
  # Examples
  #   started? "camel-core"
  #   # => true
  #
  # Returns true if the bundle is started
  def started? (name)
    bundle = list_bundles.find {|b| b[:name] == name}
    bundle[0][:context] == 'Started'
  end
end
