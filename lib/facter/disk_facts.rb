Facter.add('physical_disks') do
  confine :osfamily => :windows
  setcode do

    require 'win32ole'

    def wmi
      @wmi ||= WIN32OLE.connect("winmgmts:\\\\.\\root\\cimv2")
    end

    def physicalDisks
      wmi.ExecQuery("SELECT * FROM Win32_DiskDrive")
    end

    def disk_friendly_id(deviceID)
      deviceID.gsub("\\\\.\\",'')
    end

    def partitions(disk)
      deviceID = disk.DeviceID.gsub("\\","\\\\\\")

      partitionQuery =  "ASSOCIATORS OF {Win32_DiskDrive.DeviceID=\"#{deviceID}\"} "
      partitionQuery << "WHERE AssocClass = Win32_DiskDriveToDiskPartition"
      wmi.ExecQuery(partitionQuery)
    end

    def logicalDisks(partition)

      logicalDiskQuery =  "ASSOCIATORS OF {Win32_DiskPartition.DeviceID=\"#{partition.DeviceID}\"} "
      logicalDiskQuery << "WHERE AssocClass = Win32_LogicalDiskToPartition"

      logicalDisks = wmi.ExecQuery(logicalDiskQuery)
      
    end

    def disk_obj(disk)
      diskHash = {}
      %w[
        deviceID
        deviceID_long
        partitions
        caption
        creationClassName
        FirmwareRevision
        Index
        InterfaceType
        LastErrorCode
        Manufacturer
        MaxBlockSize
        MaxMediaSize
        MinBlockSize
        Name
        PNPDeviceID
        SCSIBus
        SCSILogicalUnit
        SCSIPort
        SCSITargetId
        SerialNumber
        Signature
        Size
        Status
        StatusInfo
        SystemName
      ].each do | prop |
          diskHash[prop] = disk.send(prop).to_s if disk.ole_respond_to?(prop)
      end

      diskHash['partitions'] = []

      diskHash
    end

    def partition_obj(partition)
      partitionHash = {}
      %w[
        Availability
        PowerManagementCapabilities
        IdentifyingDescriptions
        MaxQuiesceTime
        OtherIdentifyingInfo
        StatusInfo
        PowerOnHours
        TotalPowerOnHours
        Access
        BlockSize
        Bootable
        BootPartition
        Caption
        ConfigManagerErrorCode
        ConfigManagerUserConfig
        CreationClassName
        Description
        DeviceID
        DiskIndex
        ErrorCleared
        ErrorDescription
        ErrorMethodology
        HiddenSectors
        Index
        InstallDate
        LastErrorCode
        Name
        NumberOfBlocks
        PNPDeviceID
        PowerManagementSupported
        PrimaryPartition
        Purpose
        RewritePartition
        Size
        StartingOffset
        Status
        SystemCreationClassName
        SystemName
        Type
      ].each do | prop |
        partitionHash[prop] = partition.send(prop).to_s if partition.ole_respond_to?(prop)
      end

      partitionHash
    end

    def volume_obj(logicalDisk)
      logicalDiskHash = {}
      %w[
        Access
        Automount
        Availability
        BlockSize
        Capacity
        Caption
        Compressed
        ConfigManagerErrorCode
        ConfigManagerUserConfig
        CreationClassName
        Description
        DeviceID
        DirtyBitSet
        DriveLetter
        DriveType
        ErrorCleared
        ErrorDescription
        ErrorMethodology
        FileSystem
        FreeSpace
        IndexingEnabled
        InstallDate
        Label
        LastErrorCode
        MaximumFileNameLength
        Name
        NumberOfBlocks
        PNPDeviceID
        PowerManagementCapabilities
        PowerManagementSupported
        Purpose
        QuotasEnabled
        QuotasIncomplete
        QuotasRebuilding
        Status
        StatusInfo
        SystemCreationClassName
        SystemName
        SerialNumber
        SupportsDiskQuotas
        SupportsFileBasedCompression
      ].each do | prop |
        logicalDiskHash[prop] = logicalDisk.send(prop).to_s if logicalDisk.ole_respond_to?(prop)
      end

      # This is a convenience property added because users expect a 'Drive Letter'
      # in any object that represents volume information, even though the wmi data
      # does not contain a property by that name.
      logicalDiskHash['DriveLetter'] = logicalDisk.Name.gsub(':','')

      logicalDiskHash
    end

    disks = []

    physicalDisks.each do | disk |

      diskHash = disk_obj(disk)

      partitions(disk).each do | partition |

        partitionHash = partition_obj(partition)

        logicalDisks(partition).each do | logicalDisk |
          partitionHash['volumes'] = [] unless partitionHash.has_key?('volumes')
          partitionHash['volumes'] << volume_obj(logicalDisk)
        end

        diskHash['partitions'] << partitionHash
      end

      disks << diskHash
    end

    disks
  end
end
