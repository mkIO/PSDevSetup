# PSDevSetup

Powershel scripts for setup basic developer enviroment.

Script is using chocolatey and it is installing required software for my daily work as dev and clones git repository to specified folder.

First setup git repo url and username with password using packages.json properties:

{
    "git_repository_path" : "C:\\Code",
    "git_repository_url" : "URL",
    "git_url" : "URL",
    "git_user_name" : "name",
    "git_password" : "password"
}

To install only git stuff modify packages.json and set property just_install_git to true.

To ommit installation of software packages set install_packages to false, this will also disable git installation.

To add new chockolatey package add new intem to array packages_full with new key { "name" : name of chockolatey package, "pre" : 1 or 0 if prerelease flag is required by choco package }.

List of software to be installed
- git, poshgit, psget, git windows credential manager for windows,
- source tree,
- coemu, process explorer
- chefsdk, virtualbox,
- visual studio code, fiddler,
- slack,
- web platform install, web platform install command tool,
- nugget package explorer.

After all packages.json configuration just run setup_dev.ps1 scirpt as and administrator.
