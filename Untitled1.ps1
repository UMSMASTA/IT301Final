#Installs Hyper-V if not already installed
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools

#Creates Folder to store VHD
if (-Not (Test-Path -Path "C:\VHDs")) { 
New-Item -ItemType Directory -Path "C:\VHDs" 
}

#Creates VM (2016 Server)
New-VHD -Path "C:\VHDs\MyVM.vhdx" -SizeBytes 40GB -Dynamic
New-VM -Name "IT301Final" -MemoryStartupBytes 2GB -VHDPath "C:\VHDs\MyVM.vhdx"
Set-VM -Name "IT301Final" -ProcessorCount 2
#Make sure that the Path matches where you downloaded the ISO
Set-VMDvdDrive -VMName "IT301Final" -Path "C:\Users\Administrator\Desktop\Windows_Server_2016_Unattended_Bootable.iso"

# Ensure the VM is running, may need to do a wait here to allow the VM to boot up before making the users in the VM and other tasks?
Start-VM -Name "IT301Final"


# Function to create users inside the VM
function Create-UsersInVM {
    param (
        [string]$VMName,
        [string]$BaseUsername,
        [string]$DefaultPassword,
        [int]$NumberOfUsers
    )

    for ($i = 1; $i -le $NumberOfUsers; $i++) {
        $Username = "$BaseUsername$i"
        $Password = ConvertTo-SecureString $DefaultPassword -AsPlainText -Force

        # Command to create user inside the VM, need to work on this more nad it needs an admin password each time?
        
        $command = @"
        New-LocalUser -Name '$Username' -Password (ConvertTo-SecureString '$DefaultPassword' -AsPlainText -Force) `
            -FullName 'User $i' -Description 'Created by script' -PasswordNeverExpires -UserMayNotChangePassword:$false;
        Add-LocalGroupMember -Group 'Users' -Member '$Username';
"@

        try {
            # Execute the command inside the VM using PowerShell Direct
            Invoke-Command -VMName $VMName -ScriptBlock { param($cmd) Invoke-Expression $cmd } -ArgumentList $command
            Write-Host "Created user: $Username in VM: $VMName"
        } catch {
            Write-Warning "Failed to create user: $Username in VM: $VMName. $_"
        }
    }

    Write-Host "User creation process completed inside VM: $VMName!"
}

# Call the function to create users inside the VM
#Create-UsersInVM -VMName "IT301Final" -BaseUsername "VMUser" -DefaultPassword "SecureP@ssw0rd" -NumberOfUsers 20

