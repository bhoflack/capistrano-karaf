require 'capistrano-karaf/semver'
require 'rspec'

include Semantic_Versions

describe Semantic_Versions do
  describe 'Comparing two versions' do
    it 'Greater than compares if the installed version is greater than the provided' do
      expect(gt('2.19.0', '2.18.0')).to eq false
      expect(gt('2.18.0', '2.19.0')).to eq true
      expect(gt('2.19.0', '2.19.0')).to eq false
      expect(gt('3.0', '2.19.0')).to eq false
    end

    it 'Lower than compares if the installed version is lower than the provided' do
      expect(lt('1.0.0', '1.2.0')).to eq false
      expect(lt('1.2.1', '1.2.0')).to eq true
    end

    it 'Equal compares if the installed version is equal to the provided' do
      expect(equals('1.0.0', '1.0.0')).to eq true
      expect(equals('1.1.0', '1.1.2')).to eq false
    end
  end
end
