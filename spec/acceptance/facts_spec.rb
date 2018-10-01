require 'spec_helper_local'

describe 'Windows Disk Facts' do
  describe 'When run on a windows system' do

    it 'Should return facts' do
      expect(@stdout).to match(/physical_disks/)
    end

    it 'Should find a c: drive' do
      expect(@stdout).to match(/"DriveLetter": "C"/)
    end
  end
end