require 'sshkit'

SSHKit.config.command_map[:features_addurl] = 'features:addurl'
SSHKit.config.command_map[:features_listurl] = 'features:listurl'
SSHKit.config.command_map[:features_removeurl] = 'features:removeurl'
SSHKit.config.command_map[:features_refreshurl] = 'features:refreshurl'
SSHKit.config.command_map[:features_install] = 'features:install'
SSHKit.config.command_map[:features_uninstall] = 'features:uninstall'
SSHKit.config.command_map[:features_list] = 'features:list'
SSHKit.config.command_map[:features_info] = 'features:info'
SSHKit.config.command_map[:headers] = 'headers'
SSHKit.config.command_map[:list] = 'osgi:list'
SSHKit.config.command_map[:log_set] = 'log:set'
SSHKit.config.command_map[:stop] = 'osgi:stop'
SSHKit.config.command_map[:start] = 'osgi:start'

def add_url (url)
    execute(:features_addurl, url)
end


def remove_artifact_urls (groupID, artifactID)
   urlsToRemove=list_urls.select {|url| url['groupID']==groupID&&url['artifactID']==artifactID}	
   urlsToRemove.each do |url|   	
	remove_url ("mvn:"+url["groupID"]+"/"+url["artifactID"]+"/"+url["version"]+"/xml/features")
   end
end

def remove_url (url)
    execute(:features_removeurl, url)
end

def features_refreshurl
    execute(:features_refreshurl)
end

def feature_install (name)
    execute(:features_install, name)
end

def feature_uninstall (name)
    if (feature_installed? (name))
	execute(:features_uninstall, name)
    else
	puts "features:"+name+" is not installed so does not need to uninstall it"
    end
end

def log_set (level)
    execute(:log_set, level)
end

def start (bundleId)
    execute(:start, bundleId)
end

def stop (bundleId)
    execute(:stop, bundleId)
end

def fragment_bundle? (bundleId)
    headers = capture(:headers)
    headers.lines.any? {|l| l.match('^Fragment-Host.*')}
end

def break_listing (matcher,data)
    breaklist = []
  data.lines.each do |line|
    m = matcher.match(line)
    if m then
      breaklist.push(m)
    end
  end
  breaklist.collect {|m| Hash[m.names.zip(m.captures)]}
end

def list_urls ()
  url_line_matcher = %r{
				(?<status> \w+){0}
				(?<groupID> [\d\w\.\-]+){0}
				(?<artifactID> [\w\.\-]+){0}
				(?<version> [\w\.\-]+){0} 
			\s*\g<status>\s*mvn\:\g<groupID>\/\g<artifactID>\/\g<version>.*
				}x
  data=capture(:features_listurl)
  break_listing url_line_matcher,data
end

def list_features ()
  feature_line_matcher = %r{
				(?<status> \w+){0}
				(?<version> [\d\w\-\.\s]+){0}
				(?<name> [\w\-\:]+){0}
				(?<repository> [\w\-\s\:\.]+){0}
			^\[\s*\g<status>\s*\]\s\[\s*\g<version>\s*\]\s*\g<name>\s*\g<repository>}x
  data=capture(:features_list)
  break_listing feature_line_matcher,data
end

def list_bundles ()
  bundle_line_matcher = %r{(?<id> \d+){0}
                           (?<status> \w+){0}
                           (?<blueprint> \w*){0}
                           (?<context> \w*){0}
                           (?<level> \d+){0}
                           (?<name> [\w\s\-\:]+){0}
                           (?<version> .+){0}

                           ^\[\s*\g<id>\]\s\[\s*\g<status>\s*\]\s\[\s*\g<blueprint>\s*\]\s\[\s*\g<context>\s*\]\s\[\s*\g<level>\s*\]\s\g<name>\s\(\g<version>\)
                          }x
      
  data = capture(:list)

  break_listing bundle_line_matcher,data
end

def wait_for_all_bundles (timeout = 5, sleeptime = 1, &pred)
  timeout1 = Time.now + timeout
  
  until Time.now > timeout1 or list_bundles.all? { |b| pred.call b} 
    puts "Some bundles are still failing the predicate"
    sleep sleeptime
  end
end

def feature_installed? (name)
  feature=list_features.find {|f| f['name']==name}
  if (!feature)
	nil
  else
	feature['status']=='installed'
  end
end

def wait_for_bundle (timeout = 5, sleeptime = 1, &pred)
  timeout1 = Time.now + timeout

  while Time.now < timeout1 and list_bundles.none? { |b| pred.call b} 
    puts "Bundle not yet started"
    sleep sleeptime
  end
end


def started? (name)
  bundle = list_bundles.find {|b| b[:name] == name}
  bundle[0][:context] == 'Started'
end

def list ()
    capture(:features_list)
end

def headers (bundle)
    data = capture(:headers, bundle)
    extract_bundle_headers(data)
end

def feature_bundles (name)
    data = capture(:features_info, name)
    extract_bundles_from_feature(data)
end

def feature_bundles_numbers (name)
  bundles = list_bundles
  bundleIds = bundles.map {|bundle| bundle[:id]}
  bundleHeaders = bundleIds.map {|bundleId| headers(bundleId).store(:bundleId, bundleId)}
  featureBundles = feature_bundles(name)
  bundlesInFeature = bundles.select {|b| find_feature_bundle(featureBundles, b[:artifactId], b[:version] != nil)}
  bundlesInFeature.map {|b| b[:id]}  					  
end

def find_feature_bundle (featureBundles, name, version)
  featureBundles.select {|fb| fb["Bundle-SymbolicName"] == name && fb["Bundle-Version"] == version }
end

def extract_bundle_headers (headers)
  re = /(.+) = (.+)/
  header =  {}
  headers.lines.map {|l| m = l.match(re); if m then header[m[1].strip!] = m[2] end}
  header
end

def extract_bundles_from_feature (data)
  bundles = []
  data.lines.each do |l|
    m = l.match(/.*mvn:(?<GroupId>[\w\.]+)\/(?<ArtifactId>[-\w\.]+)\/(?<Version>[-\d\w\.]+)/)
    if m then 
      bundles.push({:groupId 	=> m['GroupId'],
		    :artifactId	=> m['ArtifactId'],
		    :version	=> m['Version']})
    end
  end
  bundles
end
