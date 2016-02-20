# General variables
$gitPath = "C:\Program Files\Git"
# Setting PATH
# Add Git executables to the mix.
[System.Environment]::SetEnvironmentVariable("PATH", $Env:Path + ";" + $gitPath)
# Setup Home so that Git doesn't freak out.
[System.Environment]::SetEnvironmentVariable("HOME", (Join-Path $Env:HomeDrive $Env:HomePath), "Process")

###############################################################################
#                              Configuration                                  #
###############################################################################

# Available color constants:
#
# Black White
# Gray DarkGray
# Red DarkRed
# Blue DarkBlue
# Green DarkGreen
# Yellow DarkYellow
# Cyan DarkCyan
# Magenta DarkMagenta

# Prompt symbol

$defaultPrompt    = "$"
$adminPrompt      = "#"

# Prompt colors

$backgroundColor          = 'Black'
$adminBackgroundColor     = 'Black'
$ClearBackground          = 'true'

$userAtHostColor          = 'Gray'
$pathColor                = 'Cyan'
$gitBranchColor           = 'Red'
$promptColor              = 'White'

# ls output colors

$lsDirectoryColor         = 'DarkCyan'
$lsCompressedColor        = 'Yellow'
$lsExecutableColor        = 'Cyan'
$lsLibraryColor           = 'Gray'
$lsConfigColor            = 'Yellow'
$lsTextFilesColor         = 'DarkCyan'

# ls file extension matching

$regex_opts = ([System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Compiled) 
$compressed = New-Object System.Text.RegularExpressions.Regex('\.(zip|tar|gz|rar)$', $regex_opts) 
$executable = New-Object System.Text.RegularExpressions.Regex('\.(exe|bat|cmd|py|pl|ps1|psm1|vbs|rb|reg|fsx)$', $regex_opts) 
$dll_pdb    = New-Object System.Text.RegularExpressions.Regex('\.(dll|pdb)$', $regex_opts) 
$configs    = New-Object System.Text.RegularExpressions.Regex('\.(config|conf|ini|xml)$', $regex_opts) 
$text_files = New-Object System.Text.RegularExpressions.Regex('\.(txt|cfg|conf|ini|csv|log)$', $regex_opts) 

# checking user privileges

$Global:CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$UserType = "User"
$CurrentUser.Groups | foreach { 
    if ($_.value -eq "S-1-5-32-544") {
        $UserType = "Admin" 
        $backgroundColor = $adminBackgroundColor
      } 
    }

# setting default colors

$Host.UI.RawUI.BackgroundColor            = ($bckgrnd = $backgroundColor)
$Host.UI.RawUI.ForegroundColor            = 'White'
$Host.PrivateData.ErrorForegroundColor    = 'Red'
$Host.PrivateData.ErrorBackgroundColor    = $bckgrnd
$Host.PrivateData.WarningForegroundColor  = 'Yellow'
$Host.PrivateData.WarningBackgroundColor  = $bckgrnd
$Host.PrivateData.DebugForegroundColor    = 'Cyan'
$Host.PrivateData.DebugBackgroundColor    = $bckgrnd
$Host.PrivateData.VerboseForegroundColor  = 'Green'
$Host.PrivateData.VerboseBackgroundColor  = $bckgrnd
$Host.PrivateData.ProgressForegroundColor = 'Cyan'
$Host.PrivateData.ProgressBackgroundColor = $bckgrnd

if ($ClearBackground -eq 'true') {
    Clear-Host
}

# this function is called everytime the prompt is displayed

function prompt {
     # Fun stuff if using the standard PowerShell prompt; not useful for Console2.
     # This, and the variables above, could be commented out.
     if($UserType -eq "Admin") {
       $host.UI.RawUI.WindowTitle = "" + $(get-location) + " : Admin"
       $host.UI.RawUI.ForegroundColor = "white"
       $defaultPrompt = $adminPrompt
      }
     else {
       $host.ui.rawui.WindowTitle = $(get-location)
     }

    Write-Host("")
    $status_string = ""
    $symbolicref = git symbolic-ref HEAD
    $userAtHost = "$Env:Username@$Env:ComputerName"
    $location = $(get-location)
    if($symbolicref -ne $NULL) {
        $gitBranch = "(git::" + $symbolicref.substring($symbolicref.LastIndexOf("/") +1) + ")"
        $status_string += "$userAtHost $gitBranch $location"
        $differences = (git diff-index --name-status HEAD)
        # $git_update_count = [regex]::matches($differences, "M`t").count
        # $git_create_count = [regex]::matches($differences, "A`t").count
        # $git_delete_count = [regex]::matches($differences, "D`t").count
        # $status_string += " [" + $git_update_count + "**" + $git_create_count + "++" + $git_delete_count + "--] "
        $status_string = "git::"
    }
    else {
        $status_string = "$userAtHost $defaultPrompt"
    }

    if ($status_string.Contains("git::")) {
        Write-Host $Env:Username -nonewline -foregroundcolor $userAtHostColor
        Write-Host "@" -nonewline -foregroundcolor $promptColor
        Write-Host ($Env:ComputerName + " ") -nonewline -foregroundcolor $userAtHostColor
        Write-Host ( "" + $location + " ") -nonewline -foregroundcolor $pathColor
        Write-Host ($gitBranch) -nonewline -foregroundcolor $gitBranchColor
        Write-Host (" $defaultPrompt") -nonewline -foregroundcolor $promptColor
    }
    else {
        Write-Host $Env:Username -nonewline -foregroundcolor $userAtHostColor
        Write-Host "@" -nonewline -foregroundcolor $promptColor
        Write-Host ($Env:ComputerName + " ") -nonewline -foregroundcolor $userAtHostColor
        Write-Host ( "" + $location + " ") -nonewline -foregroundcolor $pathColor
        Write-Host ("$defaultPrompt") -nonewline -foregroundcolor $promptColor
    }
    return " "
 }


# ls output renderer

function Get-ChildItemColor { 
<# 
15 .Synopsis 
16   Returns childitems with colors by type. 
17   From http://poshcode.org/?show=878 
18 .Description 
19   This function wraps Get-ChildItem and tries to output the results 
20   color-coded by type: 
21   Compressed - Yellow 
22   Directories - Dark Cyan 
23   Executables - Green 
24   Text Files - Cyan 
25   Others - Default 
26 .ReturnValue 
27   All objects returned by Get-ChildItem are passed down the pipeline 
28   unmodified. 
29 .Notes 
30   NAME:      Get-ChildItemColor 
31   AUTHOR:    Tojo2000 <tojo2000@tojo2000.com> 
32 #> 

  $fore = $Host.UI.RawUI.ForegroundColor 
 
   Invoke-Expression ("Get-ChildItem $args") | 
     %{ 
       $c = $fore 
       if ($_.GetType().Name -eq 'DirectoryInfo') { 
         $c = $lsDirectoryColor 
       } elseif ($compressed.IsMatch($_.Name)) { 
         $c = $lsCompressedColor 
       } elseif ($executable.IsMatch($_.Name)) { 
         $c = $lsExecutableColor 
       } elseif ($text_files.IsMatch($_.Name)) { 
         $c = $lsTextFilesColor 
       } elseif ($dll_pdb.IsMatch($_.Name)) { 
         $c = $lsLibraryColor
       } elseif ($configs.IsMatch($_.Name)) { 
         $c = $lsConfigColor
       } 
       $Host.UI.RawUI.ForegroundColor = $c 
       echo $_ 
       $Host.UI.RawUI.ForegroundColor = $fore 
     } 
} 

function Get-ChildItem-Force { ls -Force } 

# setting ls aliases

set-alias ls Get-ChildItemColor -force -option allscope 
set-alias la Get-ChildItem-Force -option allscope 
