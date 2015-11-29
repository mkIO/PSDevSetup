# Before script run do Set-ExecutionPolicy RemoteSigned in PS console

Write-Host "Setup dev tools v 0.314 Marcin Kurtz 2015 mkurtz@future-processing.com"

# Variables
$just_install_git = $false
$install_packages = $true

# Functions
function Get-ScriptDirectory {
    Split-Path -parent $PSCommandPath
}

Function AddTo-SystemPath
{
    Param([array]$PathToAdd)
    
    $VerifiedPathsToAdd = $Null
    $PathArray = $Env:path -Split ‘;’ -replace ‘\\+$’, ”
    
    Foreach($Path in ( $PathToAdd | % { $_.TrimEnd(‘\’) } ) )
    {
    
        if($PathArray -contains $Path )
        {
            Write-Host “Currnet item in path is: $Path”
            Write-Host “$Path already exists in Path statement”
        }
        else
        {
            $VerifiedPathsToAdd += “;$Path”
        }
        
        if($VerifiedPathsToAdd -ne $null)
        {
            [Environment]::SetEnvironmentVariable(“Path”,$env:Path + $VerifiedPathsToAdd,”Process”)
        }
    }
}

Write-Host "Reading packages.json for configuration..."

$configuration_file = "packages.json"
$script_path = Get-ScriptDirectory
$configuration_json_path = join-path -path $script_path $configuration_file 

$configuration = Get-Content -Raw -Path $configuration_json_path | ConvertFrom-Json

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

$Target = $configuration.tfs_url
$User = $configuration.tfs_user_name
$Pass = $configuration.tfs_password
$CredType = "GENERIC"
$CredPersist = "LOCAL_MACHINE"

[Object] $Results = Write-Creds $Target $User $Pass $Comment $CredType $CredPersist

Write-Host "...done..."

# Git setup
Write-Host "...creating repository folder..."
$git_bin_path = Join-Path "$env:programfiles" "git\bin"
$env:Path = $env:Path + ";" + $git_bin_path

# Code folder setup
New-Item -ItemType Directory -Force -Path $configuration.repository_path > $null
cd $configuration.repository_path

Remove-Item .\* -Force -Recurse

Write-Host "...done..."
Write-Host "...cloning..."

# Now run git clone in poweshell
git clone $configuration.repository_url 2>&1 | foreach-object {$_.ToString()} | Out-File log.txt

Write-Host "...done..."
Write-Host "...setting PATH for git..."

AddTo-SystemPath $git_bin_path

Write-Host "...done. See install_log.txt and log.txt for details"