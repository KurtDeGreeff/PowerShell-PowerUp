<#
$Metadata = @{
	Title = "Mount TrueCrypt Container"
	Filename = "Mount-TrueCyptContainer.ps1"
	Description = "Mount a TrueCrypt container."
	Tags = ""
	Project = ""
	Author = "Janik von Rotz"
	AuthorContact = "http://janikvonrotz.ch"
	CreateDate = "2014-01-16"
	LastEditDate = "2014-01-16"
	Url = ""
	Version = "0.1.0"
	License = @'
This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Switzerland License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ch/ or 
send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
'@
}
#>

function Mount-TrueCyptContainer{

<#
.SYNOPSIS
    Mount a TrueCrypt container.

.DESCRIPTION
	Mount a TrueCrypt container which is defined in a PowerShell Profile configuration file.

.PARAMETER Name
	Name or Key of the containers.
    
.EXAMPLE
	PS C:\> Mount-TrueCyptContainer -Name *

.EXAMPLE
	PS C:\> Mount-TrueCyptContainer -Name "Private Container"
#>

    [CmdletBinding()]
    param(

        [Parameter(Mandatory=$true)]
		[String]
		$Name   
	)
  
    #--------------------------------------------------#
    # main
    #--------------------------------------------------#
    if(-not (Get-Command TrueCrypt)){
    
        throw ("Command TrueCrypt not available, try `"Install-PPApp TrueCrypt`"")
    }
    
    $MountedContainers = Get-PPConfiguration $PSconfigs.TrueCryptContainer.DataFile | ForEach-Object{$_.Content.MountedContainer}
    
    Get-TrueCryptContainer -Name $Name | ForEach-Object{        
        
        $TrueCryptContainer = $_
        
        $MountedContainer = $MountedContainers | where{$_.Name -eq $TrueCryptContainer.Name}
            
        if($MountedContainer){
            
            Write-Error "TrueCrypt container: $($_.Name) already mounted to drive: $($MountedContainer.Drive)"
            # output TrueCrypt data
			$_ | select Key, Name, @{L="Drive";E={$MountedContainer.Drive}}
                        
        }else{
        
            $Drive = Get-AvailableDriveLetter -FavoriteDriveLetter $_.FavoriteDriveLetter
        
            Write-Host "Mount TrueCrypt container: $($_.Name) to drive: $Drive" 
            & TrueCrypt /quit /auto /letter $Drive /volume $_.Path
            
            # update truecrypt data file
            $TrueCryptDataFiles = Get-ChildItem -Path $PSconfigs.Path -Filter $PSconfigs.TrueCryptContainer.DataFile -Recurse
            
            $(if(-not $TrueCryptDataFiles){
            
                Write-Host "Create TrueCrypt data file in config folder"                     
                Copy-Item -Path (Get-ChildItem -Path $PStemplates.Path -Filter $PSconfigs.TrueCryptContainer.DataFile -Recurse).FullName -Destination $PSconfigs.Path -PassThru
                
            }else{
            
                $TrueCryptDataFiles
                
            }) | ForEach-Object{

                $Xml = [xml](get-content $_.Fullname)
                $Element = $Xml.CreateElement("MountedContainer")
                $Element.SetAttribute("Name",$TrueCryptContainer.Name)
                $Element.SetAttribute("Drive",$Drive)
                $Content = Select-Xml -Xml $Xml -XPath "//Content"
                $Null = $Content.Node.AppendChild($Element)
                $Xml.Save($_.Fullname)
            }
			
			# output TrueCrypt data
			$_ | select Key, Name, @{L="Drive";E={$Drive}}
        }
    }
}