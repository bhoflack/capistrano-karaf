# Functions for installing / upgrading software on a karaf machine

require 'capistrano-karaf/core'
require 'capistrano-karaf/extended'
require 'capistrano-karaf/semver'

require 'net/http'
require 'rexml/document'

module Install

  include Semantic_Versions
  
  # Upgrade a list of projects in karaf
  # 
  # projects - a list of hashes containing either:
  #            - :feature_url - the string containing the feature url
  #            - :feature     - the string containing the feature name to upgrade
  #            - :version     - the string containing the version
  #            - :condition   - specifies when to upgrade the feature,  one of [ :lt, :eq, :gt ( the default ) ]
  #            - :hooks       - a map containing the hook name and the list of methods to trigger
  #                               trigger can be one of :before_upgrade_feature,
  #                                                     :before_uninstall_feature,
  #                                                     :after_uninstall_feature,
  #                                                     :before_install_feature,
  #                                                     :after_install_feature,
  #                                                     :after_upgrade_feature
  # 
  #            or:
  #            - :groupId     - the string containing the groupId of the repository
  #            - :repository  - the string containing the name of the feature repository
  #            - :feature     - the string containing the name of the feature
  #            - :version     - the string containing the version or :latest
  #            - :condition   - specifies when to upgrade the feature,  one of [ :lt, :eq, :gt ( the default ) ]
  #            - :hooks       - a map containing the hook name and the list of methods to trigger
  #                               trigger can be one of :before_upgrade_feature,
  #                                                     :before_uninstall_feature,
  #                                                     :after_uninstall_feature,
  #                                                     :before_install_feature,
  #                                                     :after_install_feature,
  #                                                     :after_upgrade_feature
  #
  #
  # args - a hash containing optional args:
  #         - :startlevel_before_upgrade - the number of the startlevel to go to before upgrading
  #         - :startlevel_after_upgrade  - the number of the startlevel to go to after upgrading
  #
  #
  # Examples
  #   upgrade([{:feature_url => "mvn:repository/featurea/xml/features/1.1.0",
  #             :feature => "featurea",
  #             :version => "1.1.0",
  #             :condition => gt
  #            },
  #            {:feature_url => "mvn:repository/featureb/xml/features/1.2.0",
  #             :feature => "featureb",
  #             :version => "1.2.0",
  #             :condition => gt
  #            },
  #            {:groupId => "repository",
  #             :repository => "featureb",
  #             :feature => "featureb",
  #             :version => :latest             
  #            }])
  #  # => nil
  #
  # Returns nothing
  def upgrade (projects, args={})
    args = {:startlevel_before_upgrade => 60, :startlevel_after_upgrade => 100}.merge(args)
    features = list_features()

    to_uninstall, to_install = calculate_upgrade_actions(projects, features)

    # decrease the start level
    startlevel_set args[:startlevel_before_upgrade]

    wait_for_all_bundles(:timeout => 180, :sleeptime => 10) do |b|
      if b[:level].to_i > args[:startlevel_before_upgrade] 
        b[:status] == "Resolved"
      else
        true
      end
    end

    # first start uninstalling features in reverse order
    to_uninstall.reverse.each do |f| 
      trigger_event(f, :before_uninstall_feature)
      feature_uninstall(f[:name], f[:version])
      trigger_event(f, :after_uninstall_feature)
    end

    # now install the new features
    to_install.each do |f|
      remove_otherversion_urls(f[:feature_url])
      add_url(f[:feature_url])
      trigger_event(f, :before_install_feature)
      feature_install(f[:feature])
      trigger_event(f, :after_install_feature)
    end

    # increase the start level
    startlevel_set args[:startlevel_after_upgrade]
    wait_for_all_bundles(:timeout => 180, :sleeptime => 10) do |b|
      if (b[:level].to_i > args[:startlevel_before_upgrade] and 
          b[:level].to_i <= args[:startlevel_after_upgrade])
        ["Active","Resolved"].include? b[:status]
      else
        true
      end
    end

    list_bundles.find_all {|b| !b[:fragment] && b[:context] == "Failed"}
                .each {|b| restart_bundle b[:id]}

  end

  # Extract the latest version from a maven-metadata file
  #
  # Parameters
  #   - xml - A string containing the xml file
  #
  # Example 
  #   extract_latest_version(xml)
  #   # returns "2.19.1-SNAPSHOT"
  #
  # Returns a string containing the version
  def extract_latest_version (xml)
    doc = REXML::Document.new(xml)
    version = REXML::XPath.first(doc, "/metadata/versioning/latest").text
  end

  private
  def latest_snapshot_version (groupId, artifactId)
    groupId1 = groupId.split('.').join('/')
    url = "http://nexus.colo.elex.be:8081/nexus/content/groups/public-snapshots/#{groupId1}/#{artifactId}/maven-metadata.xml"
    uri = URI(url)
    maven_metadata = Net::HTTP.get(uri)    
  end

  def find_installed_with_name (features, name)
    features.select {|f| f[:name] == name and f[:status] == "installed"}
  end

  def upgrade_feature(installed_features, feature, to_install, to_uninstall)
    install_new_feature = true
    p = method(feature[:condition])
    
    installed_features.each do |f|
      trigger_event(feature, :before_upgrade_feature)
      if p.call(f[:version], feature[:version])
        to_uninstall << f
      else
        install_new_feature = false
      end
    end
    
    if install_new_feature
      to_install << feature
    end
  end

  def trigger_event (feature, event) 
    feature[:hooks].fetch(event, []).each do |h|
      if h.is_a? Proc
        h.call()
      elsif h.is_a? Symbol
        proc = method(h)
        proc.call()
      end
    end
  end

  def create_feature_hash(groupId, repository, feature, version, condition, hooks)
    version1 = nil
    if version == :latest then
      version1 = extract_latest_version(latest_snapshot_version(groupId, repository))
    else
      version1 = version
    end

    featureUrl = "mvn:#{groupId}/#{repository}/#{version1}/xml/features"
    
    {:feature_url => featureUrl,
     :feature => feature,
     :version => version1,
     :condition => condition,
     :hooks => hooks
    }    
  end

  def fragment_bundle? (bundle)
    bundle[:fragment]
  end

  def calculate_upgrade_actions (projects, features)
    to_uninstall = []
    to_install = []

    projects.each do |project|
      project = {:condition => :gt,
                 :hooks => {}}.merge(project)
     
      install_new_feature = true      
      installed_features = find_installed_with_name(features, project[:feature])

      if project.keys.include? :groupId then
        fh = create_feature_hash(project[:groupId], project[:repository], project[:feature], project[:version], project[:condition], project[:hooks])
        upgrade_feature(installed_features, fh, to_install, to_uninstall)
      else
        upgrade_feature(installed_features, project, to_install, to_uninstall)
      end
    end

    return to_uninstall, to_install
  end

  def restart_bundle (id)
    stop id
    start id
  end
end
