require 'sshkit'

SSHKit.config.command_map = 
    {
        :features_addurl    => 'features:addurl',
        :features_removeurl => 'features:removeurl',
        :features_install   => 'features:install',
        :features_list      => 'features:list',
        :features_info      => 'features:info',
        :headers            => 'headers',
        :list               => 'list'
    }

def add_url (url)
    execute(:features_addurl, url)
end

def remove_url (url)
    execute(:features_removeurl, url)
end

def feature_install (name)
    execute(:features_install, name)
end

def feature_uninstall (name)
    execute(:features_uninstall, name)
end

def list_bundles ()
  bundle_line_matcher = /^\[(?<BundleId>[ \d]+)\] \[(?<BundleStatus>[ \w]+)\] \[[ ]*\] \[(?<ContextStatus>[ \w]+)\] \[(?<BundleLevel> [ \d]+)\] (?<BundleName>[\w\-\:]+) \((?<BundleVersion>.+)\)/

  
    data = capture(:list)
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
      bundles
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
    m = l.match(/.*mvn:(?<GroupId>[\w\.]+)\/(?<ArtifactId>[\w-\.]+)\/(?<Version>[\d\w\.-]+)/)
    if m then 
      bundles.push({:groupId 	=> m['GroupId'],
		    :artifactId	=> m['ArtifactId'],
		    :version	=> m['Version']})
    end
  end
  bundles
end
