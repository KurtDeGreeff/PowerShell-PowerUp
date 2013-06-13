﻿function Connect-SCPSession{
    <#
	    .SYNOPSIS
		    Remote management for scp sessions

	    .DESCRIPTION
		    Starts a scp session with the parameters from the remote config file.

	    .PARAMETER  Name
		    Servername (Key or Name from the remote config file for preconfiguration)
            
	    .PARAMETER  User
		    Username (overwrites remote config file parameter)
            
	    .PARAMETER  Port
		    Port (overwrites remote config file parameter)
                                  
	    .PARAMETER  PrivatKey
		    PrivatKey (overwrites remote config file parameter)
            
	    .EXAMPLE
		   Connect-SCPSession -Names firewall

    #>

	#--------------------------------------------------#
	# Parameter
	#--------------------------------------------------#
	param (
        [parameter(Mandatory=$true)][string]
		$Name,
        [parameter(Mandatory=$false)][string]
		$User,
        [parameter(Mandatory=$false)][int]
		$Port,
        [parameter(Mandatory=$false)][string]
		$PrivatKey
	)

	$Metadata = @{
		Title = "Connect SCP Session"
		Filename = "Connect-SCPSession.ps1"
		Description = ""
		Tags = "powershell, remote, session, scp"
		Project = ""
		Author = "Janik von Rotz"
		AuthorContact = "www.janikvonrotz.ch"
		CreateDate = "2013-05-13"
		LastEditDate = "2013-06-12"
		Version = "2.0.0"
		License = @'
This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License. 
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/3.0/ or
send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
'@
}


    #--------------------------------------------------#
    # main
    #--------------------------------------------------#
   if (Get-Command "winscp.exe"){ 

        # Load Configurations
    	$Server = Get-RemoteConnections -Names $Name -FirstEntry

    		
        # set port
        
        # get port from Protocol
        if(!$Port){
            $Server.Protocol | %{
                if ($_.Name -eq "scp" -and $_.Port -ne ""){
                    $Port = $_.Port
                }
            }
        }
        if(!$Port -or $Port -eq 0){
            $Port = 22
        }

        # set servername
        $Servername = $Server.Name
        
        # set username
        if(!$User){$User = $Server.User}
         
        # set privatkey
        if(!$PrivatKey){$PrivatKey = Invoke-Expression ($Command = '"' + $Server.PrivatKey + '"')}
                        
		#Set Protocol
        if($PrivatKey -eq ""){
            Invoke-Expression ("WinSCP.exe scp://$User@$Servername" + ":$Port")
        }else{
            Invoke-Expression ("WinSCP.exe scp://$User@$Servername :$SCPPort" + ":$Port /privatekey='$PrivatKey'" )
        }
    
    }
}