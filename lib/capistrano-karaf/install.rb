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
  #            }
  #            }])
  #  # => nil
  #
  # Returns nothing
  def upgrade (projects)
    features = list_features()
    projects.each do |project|
      project = {:condition => :gt,
                 :hooks => {}}.merge(project)
     
      install_new_feature = true      
      installed_features = find_installed_with_name(features, project[:feature])

      if project.keys.include? :groupId then
        fh = create_feature_hash(project[:groupId], project[:repository], project[:feature], project[:version], project[:condition], project[:hooks])
        upgrade_feature(installed_features, fh)
      else
        upgrade_feature(installed_features, project)
      end
    end
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
    features.select {|f| f["name"] == name and f["status"] == "installed"}
  end

  def upgrade_feature(installed_features, feature)
    install_new_feature = true
    p = method(feature[:condition])
    
    installed_features.each do |f|
      trigger_event(feature, :before_upgrade_feature)
      if p.call(f["version"], feature[:version])
        trigger_event(feature, :before_uninstall_feature)
        feature_uninstall("#{feature[:feature]}/#{f['version']}")
        trigger_event(feature, :after_uninstall_feature)
      else
        install_new_feature = false
      end
    end
    

    if install_new_feature 
      remove_otherversion_urls(feature[:feature_url])
      add_url(feature[:feature_url])
      trigger_event(feature, :before_install_feature)
      feature_install(feature[:feature])
      trigger_event(feature, :after_install_feature)     
    end
    trigger_event(feature, :after_upgrade_feature)
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
end
