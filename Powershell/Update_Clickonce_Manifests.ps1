# Scripts updates and signs clickonce manifests
# Folders must have been set up and all files copied prior to this script
# Mage params: https://msdn.microsoft.com/en-us/library/acz3y3te%28v=vs.110%29.aspx
$AppFilesFolder = 'ApplicationFiles_9_0_44365'
$CliconceFolder = 'clickonce - Copy'
$certFile = 'D:\dynamics\certificate\HATPersonalInformationExchange.pfx'
$version = "9.0.44365.3"
$name = "Delux NAV 2016"
$procArchitecture = "x86" #msil, x86, ia64
$navVersion = "90"
$providerUrl = "http://ahven.mvw.sise/"


Write-Host "Executing"
$env:Path = "C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\NETFX 4.0 Tools;C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin"
cd C:\inetpub\wwwroot\$CliconceFolder\Deployment\$AppFilesFolder -ErrorAction Stop
Copy-Item  "${env:ProgramFiles(x86)}\Microsoft Dynamics NAV\$navVersion\ClickOnce Installer Tools\TemplateFiles\Deployment\ApplicationFiles\*" -Force -ErrorAction Stop 
   
Remove-Item Web.config -Force -ErrorAction SilentlyContinue
# Update manifest
mage.exe -Update Microsoft.Dynamics.Nav.Client.exe.manifest -Processor $procArchitecture -Version $version -Name $name -FromDirectory .\ 
# Sign manifest
mage.exe -sign Microsoft.Dynamics.Nav.Client.exe.manifest -certfile $certFile

cd ..
Copy-Item  "${env:ProgramFiles(x86)}\Microsoft Dynamics NAV\$navVersion\ClickOnce Installer Tools\TemplateFiles\Deployment\Microsoft.Dynamics.Nav.Client.application" -Force -ErrorAction Stop 
mage -Update Microsoft.Dynamics.Nav.Client.application `
    -AppManifest $AppFilesFolder\Microsoft.Dynamics.Nav.Client.exe.manifest `
    -Name $name `
    -Version $version `
    -Publisher 'HAT Systems' `
    -SupportURL "https://msdn.microsoft.com/en-us/library/hh173988(v=nav.$navVersion).aspx" `
    -ProviderURL $providerUrl$CliconceFolder/Deployment/Microsoft.Dynamics.Nav.Client.application `
    -CertFile $certFile `
    -Processor $procArchitecture `
    -MinVersion $version
  
# create new web config file    
CD $AppFilesFolder
New-Item Web.config -type file -value '<?xml version="1.0" encoding="UTF-8"?><configuration><system.webServer><directoryBrowse enabled="true" /><staticContent>'
Add-Content -Path Web.config -Value '<mimeMap fileExtension=".config" mimeType="application/x-msdownload" />'
Add-Content -Path Web.config -Value '<mimeMap fileExtension=".tlb" mimeType="application/x-msdownload"/>'
Add-Content -Path Web.config -Value '<mimeMap fileExtension=".olb" mimeType="application/x-msdownload"/>'
Add-Content -Path Web.config -Value '<mimeMap fileExtension=".pdb" mimeType="application/x-msdownload"/>'
Add-Content -Path Web.config -Value '<mimeMap fileExtension=".hh" mimeType="application/x-msdownload"/>'
Add-Content -Path Web.config -Value '<mimeMap fileExtension=".xss" mimeType="application/x-msdownload"/>'
Add-Content -Path Web.config -Value '<mimeMap fileExtension=".xsc" mimeType="application/x-msdownload"/>'
Add-Content -Path Web.config -Value '<mimeMap fileExtension=".stx" mimeType="application/x-msdownload"/>'
Add-Content -Path Web.config -Value '<mimeMap fileExtension=".msc" mimeType="application/x-msdownload"/>'
Add-Content -Path Web.config -Value '<mimeMap fileExtension=".flf" mimeType="application/x-msdownload"/>'
Add-Content -Path Web.config -Value '<mimeMap fileExtension=".rdlc" mimeType="application/x-msdownload"/>'
Add-Content -Path Web.config -Value '<mimeMap fileExtension=".sln" mimeType="application/x-msdownload"/>'
Add-Content -Path Web.config -Value '<mimeMap fileExtension=".psd1" mimeType="application/x-msdownload"/>'
Add-Content -Path Web.config -Value '<mimeMap fileExtension=".ps1" mimeType="application/x-msdownload"/>'
Add-Content -Path Web.config -Value '<mimeMap fileExtension=".ps1xml" mimeType="application/x-msdownload"/>'
Add-Content -Path Web.config -Value '<mimeMap fileExtension=".psm1" mimeType="application/x-msdownload"/>'
Add-Content -Path Web.config -Value '</staticContent><security><requestFiltering><fileExtensions><remove fileExtension=".config" /></fileExtensions></requestFiltering></security></system.webServer></configuration>'
