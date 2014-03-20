require 'capistrano-karaf/install'
require 'rspec'



include Install

describe "Parsing the maven-metadata file" do
    it "Extracts the latest version from the maven-metadata file" do
        version = extract_latest_version(%Q{<?xml version="1.0" encoding="UTF-8"?>
<metadata>
  <groupId>com.melexis.repository</groupId>
  <artifactId>conti-regensburg-repo</artifactId>
  <versioning>
    <latest>2.19.3-SNAPSHOT</latest>
    <versions>
      <version>2.18.0-SNAPSHOT</version>
      <version>2.18.1-SNAPSHOT</version>
      <version>2.19.1-SNAPSHOT</version>
      <version>2.19.2-SNAPSHOT</version>
      <version>2.19.3-SNAPSHOT</version>
    </versions>
    <lastUpdated>20140219140912</lastUpdated>
  </versioning>
</metadata>})

        expect(version).to eq("2.19.3-SNAPSHOT")
    end
end
