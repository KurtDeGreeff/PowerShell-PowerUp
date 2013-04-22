if($Host.Version.Major -gt 2){
	powershell -Version 2 $MyInvocation.MyCommand.Definition
	exit
}

$Metadata = @{
	Title = "Profile Installation"
	Filename = "Microsoft.PowerShell_profile.install.ps1"
	Description = ""
	Tags = "powershell, profile, installation"
	Project = ""
	Author = "Janik von Rotz"
	AuthorContact = "www.janikvonrotz.ch"
	CreateDate = "2013-03-18"
	LastEditDate = "2013-04-22"
	Version = "4.1.0"
	License = @'
This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License.�
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/3.0/ or
send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
'@
}

if($Host.Version.Major -lt 2){
    throw "Only compatible with Powershell version 2 and higher"
}else{

    [string]$WorkingPath = Get-Location	
    $Features = @()
    
    #--------------------------------------------------#
    #  Settings
    #--------------------------------------------------#
    $PSConfig = .\Microsoft.PowerShell_profile.config.ps1
	$PSProfileScriptName = "Microsoft.PowerShell_profile.ps1"
	$PSProfileISEScriptName = "Microsoft.PowerShellISE_profile.ps1"

    #--------------------------------------------------#
    #  Include Modules
    #--------------------------------------------------#
	$env:PSModulePath += ";"+ ($PSConfig.modules.Path)
	Import-Module Pscx
    	
	#--------------------------------------------------#
	# Autoinclude Functions
	#--------------------------------------------------#
    #Include functions
    $IncludeFolders = @()
    $IncludeFolders += $PSConfig.functions.Path
    $IncludeFolders += get-childitem ($PSConfig.functions.Path) -Recurse | where{$_.PSIsContainer} | foreach {$_.Fullname}
    foreach ($IncludeFolder in $IncludeFolders){
	    Set-Location $IncludeFolder
	    get-childitem $IncludeFolder | where{ ! $_.PSIsContainer} | foreach {. .\$_}
    }
	Set-Location $WorkingPath
    
	#--------------------------------------------------#
    # System Settings
    #--------------------------------------------------#
    # Add module path to the system variables
    Add-PathVariable -Value $PSconfig.modules.Path -Name PSModulePath -Target Machine
    
    #Load configurations
    $ConfigFiles = Get-ConfigurationFilesContent -Path $PSConfig.configs.Path -SearchExpression "*.profile.config.*"
	
	
    foreach($ConfigFile in $ConfigFiles){
        
        $Config = $ConfigFile.Content.Configuration
        
		#--------------------------------------------------#
		# Add Registry Keys
		#--------------------------------------------------#
        foreach ($RegistryEntry in $Config.RegistryEntries.RegistryEntry)
        {
	        Set-ItemProperty -Path $RegistryEntry.Path -Name $RegistryEntry.Name -Value $RegistryEntry.Value
            [string]$Name =  $RegistryEntry.Name
		    Write-Warning "`nAdded registry entry: $Name"
        }

		#--------------------------------------------------#
		# Add System Variables
		#--------------------------------------------------#
        foreach ($SystemVariable in $Config.SystemVariables.SystemVariable)
        {
	        if($SystemVariable.RelativePath -eq "true")
	        {
                #Gets the static path from a relative path
		        $StaticPath = Convert-Path -Path (Join-Path -Path $(Get-Location).Path -Childpath $SystemVariable.Value)
                
		        Add-PathVariable -Value $StaticPath -Name $SystemVariable.Name -Target $SystemVariable.Target
	        }else{
		        Add-PathVariable -Value $SystemVariable.Value -Name $SystemVariable.Name -Target $SystemVariable.Target
	        }
		    Write-Warning "`nAdded path variable: $Name"
        }
        
        # Collect features
    	foreach($Feature in $Config.Features.Feature){
    		$Features += $Feature.Name
    	}
	}
	
	#--------------------------------------------------#
	# Features
	#--------------------------------------------------#
	$Content = ""
    $ContentISE = ""
    $ContentISEArray = ""
    
	# Git Update Task
	if($Features -contains "Git Update Task"){
		# Settings						
		$PathToTask = Get-ChildItem -Path $PSConfigs.tasks.Path -Filter GitUpdateTask.xml -Recurse
		$PathToScript = Get-ChildItem -Path $PSConfigs.tasks.Path -Filter Git-Update.ps1 -Recurse
		
		# Update task definitions
		[xml]$TaskDefinition = (get-content $PathToTask.Fullname)
		$TaskDefinition.Task.Actions.Exec.Arguments = $PathToScript.Fullname
		$TaskDefinition.Task.Actions.Exec.WorkingDirectory = $WorkingPath
		$TaskDefinition.Save($PathToTask.Fullname)

		# Create task
		[string]$Name =  $Feature.Name
		SchTasks /Create /TN "$Name" /XML $PathToTask.Fullname
		Write-Warning "`nAdded system task: $Name"
	}

	# Powershell Remoting
	if($Features -contains "Powershell Remoting"){
		Enable-PSRemoting
		Set-Item WSMan:\localhost\Client\TrustedHosts "RemoteComputer" -Force
		Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB 1024
		restart-Service WinRM
		Write-Warning "`nPowershell Remoting enabled"
	}
	
	# Enable Open Powershell here
	if($Features -contains "Enable Open Powershell here"){
		Enable-OpenPowerShellHere
		Write-Warning "`nAdded 'Open PowerShell Here' to context menu"
	}
    
	# Metadata
	$Content += @'
    
$Metadata = @{
	Title = "Powershell Profile"
	Filename = "Microsoft.PowerShell_profile.ps1"
	Description = ""
	Tags = "powershell, profile"
	Project = ""
	Author = "Janik von Rotz"
	AuthorContact = "www.janikvonrotz.ch"
	CreateDate = "2013-04-22"
	LastEditDate = "2013-04-22"
	Version = "3.1.0"
	License = "This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License.�To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/3.0/ or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA."
}

'@
    
    # Metadata ISE    
    $ContentISE += @'
    
$Metadata = @{
	Title = "Powershell ISE Profile"
	Filename = "Microsoft.PowerShellISE_profile.ps1"
	Description = ""
	Tags = "powershell, ise, profile"
	Project = ""
	Author = "Janik von Rotz"
	AuthorContact = "www.janikvonrotz.ch"
	CreateDate = "2013-04-22"
	LastEditDate = "2013-04-22"
	Version = "3.1.0"
	License = "This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License.�To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/3.0/ or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA."
}

'@
    $ContentISEArray += $ContentISE

	# Main
	$Content += $ContentISE = @'

#--------------------------------------------------#
# Main
#--------------------------------------------------#
[string]$WorkingPath = Get-Location
$PSConfig = "\Microsoft.PowerShell_profile.config.ps1"
$PathToScript = Split-Path $MyInvocation.MyCommand.Definition -Parent
$PSConfig = Invoke-Expression ($PathToScript + $PSConfig)

'@
    $ContentISEArray += $ContentISE
	
	# Custom PowerShell CLI
	if($Features -contains "Custom PowerShell CLI"){
	$Content += @'

#--------------------------------------------------#
# Custom PowerShell CLI
#--------------------------------------------------#
$PromptSettings = (Get-Host).UI.RawUI
# $PromptSettings.ForegroundColor = "Black"
# $PromptSettings.BackgroundColor = "White"
$PromptSettings.BufferSize.Width = 120
$PromptSettings.BufferSize.Height = 999
$PromptSettings.WindowSize.Width = 120
$PromptSettings.WindowSize.Height = 50
$PromptSettings.MaxWindowSize.Width = 120
$PromptSettings.MaxWindowSize.Height = 50
$PromptSettings.MaxPhysicalWindowSize.Width = 120
$PromptSettings.MaxPhysicalWindowSize.Height = 50
# $PromptSettings.WindowTitle = "PowerShell"

'@}

	# Autoinclude Functions
	if($Features -contains "Autoinclude Functions"){
	$Content += $ContentISE = @'

#--------------------------------------------------#
# Autoinclude Functions
#--------------------------------------------------#
$IncludeFolders = @()
$IncludeFolders += $PSConfig.functions.Path
$IncludeFolders += get-childitem ($PSConfig.functions.Path) -Recurse | where{$_.PSIsContainer} | foreach {$_.Fullname}
foreach ($IncludeFolder in $IncludeFolders){
	Set-Location $IncludeFolder
	get-childitem $IncludeFolder | where{ ! $_.PSIsContainer} | foreach {. .\$_}
}

'@}
	$ContentISEArray += $ContentISE
    
	# Custom Aliases
	if($Features -contains "Custom Aliases"){
	$Content += $ContentISE = @'

#--------------------------------------------------#
# Custom Aliases
#--------------------------------------------------#	
nal -Name rdp -Value "Connect-RDPSession"
nal -Name rps -Value "Connect-PSSession"

'@}
    $ContentISEArray += $ContentISE

	# Transcript Logging
	if($Features -contains "Transcript Logging"){
	$Content += @'

#--------------------------------------------------#
# Transcript Logging
#--------------------------------------------------#	
Start-Transcript -path ($PSConfig.logs.Path + "\Powershell Commands " + $(Get-LogStamp) + ".txt")

'@}

	# Main End
	$Content += $ContentISE = @'

#--------------------------------------------------#
# Main End
#--------------------------------------------------#
Set-Location $WorkingPath

'@
    $ContentISEArray += $ContentISE
    
    # Multi Remote Management
    if($Features -contains "Multi Remote Management"){
    
        # Remote config file
        $ContentRemoteConfigXml = @'

<?xml version="1.0" encoding="UTF-8" ?>
<Content>
	<Metadata>
		<Title>Remote Server Configurations</Title>
		<Filename>EXAMPLE.remote.config.xml</Filename>
		<Description></Description>
		<Tags>powershell, configuration, remote, session</Tags>
		<Project></Project>
		<Author>Janik von Rotz</Author>
		<AuthorContact>www.janikvonrotz.ch</AuthorContact>
		<CreateDate>2013-03-28</CreateDate>
		<LastEditDate>2013-04-11</LastEditDate>
		<Version>2.0.0</Version>
	</Metadata>
	
	<Servers>
		<Name>linux1</Name>
		<Server>ServerLinux1</Server>
		<User>Root</User>
		<Description></Description>
		<Protocol>ssh,scp</Protocol>
		<SnapIns></SnapIns>
		<PrivatKey></PrivatKey>
	</Servers>
	
	<Servers>
		<Name>ServerSharePoint1</Name>
		<Server>ServerSharePoint1</Server>
		<User>Domain\Administrator</User>
		<Description></Description>
		<Protocol>rdp,rps</Protocol>
		<SnapIns>Microsoft.SharePoint.PowerShell</SnapIns>
		<PrivatKey></PrivatKey>
	</Servers>
		
</Content>

'@
        # Write content to config file
        Set-Content -Value $ContentRemoteConfigXml -Path ($PSConfig.configs.Path + "\EXAMPLE.remote.config.xml")
        
        # RDP Default file
        $ContentDefaultRDP = @'

screen mode id:i:1
use multimon:i:0
desktopwidth:i:1600
desktopheight:i:1024
session bpp:i:32
winposstr:s:0,1,155,144,1628,1032
compression:i:1
keyboardhook:i:2
audiocapturemode:i:0
videoplaybackmode:i:1
connection type:i:2
displayconnectionbar:i:1
disable wallpaper:i:1
allow font smoothing:i:0
allow desktop composition:i:0
disable full window drag:i:1
disable menu anims:i:1
disable themes:i:0
disable cursor setting:i:0
bitmapcachepersistenable:i:1
full address:s:
audiomode:i:0
redirectprinters:i:1
redirectcomports:i:0
redirectsmartcards:i:1
redirectclipboard:i:1
redirectposdevices:i:0
redirectdirectx:i:1
autoreconnection enabled:i:1
authentication level:i:2
prompt for credentials:i:1
negotiate security layer:i:1
remoteapplicationmode:i:0
alternate shell:s:
shell working directory:s:
gatewayhostname:s:
gatewayusagemethod:i:4
gatewaycredentialssource:i:4
gatewayprofileusagemethod:i:0
promptcredentialonce:i:1
use redirection server name:i:0
drivestoredirect:s:

'@
        # Write content to config file
        Set-Content -Value $ContentDefaultRDP -Path ($PSConfig.configs.Path + "\Default.rdp")
    }

	# Write content to script file
    Set-Content -Value $Content -Path $PSProfileScriptName
        
    if($Features -contains "Add ISE Profile Script"){
        Set-Content -Value $ContentISEArray -Path $PSProfileISEScriptName
    }
    
    

	#--------------------------------------------------#
	# Write PowerShell Profile script
	#--------------------------------------------------#
	
	#--------------------------------------------------#
	# Powershell Profile Link
	#--------------------------------------------------#

	# Create Powershell Profile
	if (!(Test-Path $Profile)){

		  # Create a profile
		New-Item -path $Profile -type file -force
	}

	# Link Powershell Profile
	$SourcePath = Split-Path $profile -parent
	$ScriptName = $MyInvocation.MyCommand.Name

	if (!(Test-Path ($SourcePath + "\" + $ScriptName) -PathType Leaf))
	{
		# Rename default source
		Rename-Item $SourcePath ($SourcePath + "-Obsolete")
 
		# Create a shortcut to the existing powershell profile
		New-Symlink $SourcePath $WorkingPath
	}
	
	Write-Host "`nFinished" -BackgroundColor Black -ForegroundColor Green
	Read-Host "`nPress Enter to exit"

}
