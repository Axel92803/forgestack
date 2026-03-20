# Create the VM

New-VM -Name "forgestack-target" \

	-MemoryStartupBytes 1GB \

	-Generation 2 \

	-NewVHDPath "C:\HyperV\forgestack-target.vhdx" \

	-NewVHDSizeBytes 20GB \

	-SwitchName "Default Switch"

# Disable Secure Boot

Set-VMFirmware -VMName "forgestack-target" \

	-EnableSecureBoot Off

# Attach the ISO

Add-VMDvdDrive -VMName "forgestack-target" \

	-Path "C:\ISOs\debian-12-amd64-netinst.iso"

# Set boot order (DVD first)

$dvd = Get-VMDvdDrive -VMName "forgestack-target"

Set-VMFirmware -VMName "forgestack-target" \

	-FirstBootDevice $dvd

# Enable Guest Services
Enable-VMIntegrationService \

	-VMName "forgestack-target" \

	-Name "Guest Service Interface"

# Start the VM

Start-VM -Name "forgestack-target"
