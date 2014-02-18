# Functions for installing / upgrading software on a karaf machine

require 'capistrano-karaf/core'
require 'capistrano-karaf/extended'
require 'capistrano-karaf/semver'

module Capistrano_Karaf
  include Semantic_Versions
  
  # Upgrade a list of projects in karaf
  #
  # projects - a list of hashes containing:
  #            - :feature_url - the string containing the feature url
  #            - :feature     - the string containing the feature name to upgrade
  #            - :version     - the string containing the version
  #            - :condition      - specifies when to upgrade the feature,  one of [ :lt, :eq, :gt ( the default ) ]
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
  #            }])
  #  # => nil
  #
  # Returns nothing
  def upgrade (projects)
    features = list_features()
    projects.each do |project|
      project = {:condition => :gt}.merge(project)

      install_new_feature = true      
      installed_features = find_installed_with_name(features, project[:feature])

      p = method(project[:condition])
      installed_features.each do |f|
        if p.call(f["version"], project[:version])
          feature_uninstall("#{project[:feature]}/#{f['version']}")
        else
          install_new_feature = false
        end
      end

      if install_new_feature 
        add_url(project[:feature_url])
        feature_install(project[:feature])
      end
    end
  end

  private
  def find_installed_with_name (features, name)
    features.select {|f| f["name"] == name and f["status"] == "installed"}
  end
end
