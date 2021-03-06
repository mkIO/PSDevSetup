# Before script run do Set-ExecutionPolicy RemoteSigned in PS console

Write-Host "Setup dev tools v 0.31415 Marcin Kurtz 2015 mkurtz@future-processing.com"

# Functions
function Get-ScriptDirectory {
    Split-Path -parent $PSCommandPath
}

function global:Add-Path()
{
    [Cmdletbinding()]
    param
    (
        [parameter(Mandatory=$True, ValueFromPipeline=$True, Position=0)]
        [String[]]$AddedFolder
    )

    $OldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
    

    if (!$AddedFolder) { Return 'No Folder Supplied. $ENV:PATH Unchanged'}

    if (!(TEST-PATH $AddedFolder)) { Return 'Folder Does not Exist, Cannot be added to $ENV:PATH' }

    if ($ENV:PATH | Select-String -SimpleMatch $AddedFolder) { Return 'Folder already within $ENV:PATH' }

    $NewPath=$OldPath+’;’+$AddedFolder

    Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH –Value $newPath
    
    return $NewPath
}

Write-Host "Reading packages.json for configuration..."

$configuration_file = "packages.json"
$script_path = Get-ScriptDirectory
$configuration_json_path = join-path -path $script_path $configuration_file 

$configuration = Get-Content -Raw -Path $configuration_json_path | ConvertFrom-Json

# Variables
$install_packages = $configuration.install_packages
$just_install_git = $configuration.just_install_git
    
Write-Host "...done..."

# Packages install
if($install_packages){
    
    Write-Host "Installing required software using chocolatey..."

    iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')) 2>&1 | foreach-object {$_.ToString()} | Out-File install_log.txt

    # Installing PS 4.0
    # choco install powershell4 -version 4.0

    if($just_install_git){
        $configuration.packages_git |  foreach { 
            if($_.pre -eq 1){
                chocolatey install $_.name --pre --accept-license --confirm --force 
            }else{
                chocolatey install $_.name --accept-license --confirm --force 
            }
        }
    }else{
        $configuration.packages_full |  foreach { 
            if($_.pre -eq 1){
                chocolatey install $_.name --pre --accept-license --confirm --force 
            }else{
                chocolatey install $_.name --accept-license --confirm --force 
            }
        }
    }

    Write-Host "...done..."
}

# GIT

Write-Host "Starting Git configuration..."

Write-Host "...seting up credentials..."

# Git user credentials - git credential manager required!
$cred_man_script_name = "CredMan.ps1"
$script_path = Get-ScriptDirectory
$cred_man_script_path = join-path -path $script_path $cred_man_script_name 

. $cred_man_script_path

$Target = "git:" + $configuration.git_url
$User = $configuration.git_user_name
$Pass = $configuration.git_password
$CredType = "GENERIC"
$CredPersist = "LOCAL_MACHINE"

[Object] $Results = Write-Creds $Target $User $Pass $Comment $CredType $CredPersist

Write-Host "...done..."

# Git setup
$git_bin_path = Join-Path "$env:programfiles" "git\bin"

Write-Host "...setting PATH for git..."
$env:Path = $env:Path + ";" + $git_bin_path
Add-Path $git_bin_path

# Code folder setup
Write-Host "...creating repository folder..."
New-Item -ItemType Directory -Force -Path $configuration.git_repository_path > $null
cd $configuration.git_repository_path

Remove-Item .\* -Force -Recurse

Write-Host "...done..."
Write-Host "...cloning..."

# Now run git clone in poweshell
git clone $configuration.git_repository_url 2>&1 | foreach-object {$_.ToString()} | Out-File log.txt

Write-Host "...done. See install_log.txt and log.txt for details"

Explorer $configuration.git_repository_path