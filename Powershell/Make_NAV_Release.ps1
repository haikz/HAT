# exports DEV and LIVE ANV objects, copies them into a release folder and creates release zip file
# Developer licence with name "HAT_Licence.flf" and customer licence with name "Cust_licence.flf" must must be in same fiolder as this script
# options:
$release = 'R132'
$releaseObjectFilter = '"*R132*"'  # NAV Version list filter. NB quotation marks as: '"*TV-137*|*TV-112*"'

$workFolder = "C:\dynamics\RELEASE\"
$devNavinstance = "DynamicsNAV90DEV"
$liveNavinstance = "DynamicsNAV90"
$DevDB = "NAV2016_DEV"
$LiveDb = "NAV2016_TEST"
$ServerName = "TEST-ERP-SQL.ntserver2.sise"             

Set-ExecutionPolicy RemoteSigned -Force
Import-Module "${env:ProgramFiles}\Microsoft Dynamics NAV\90\Service\NavAdminTool.ps1"
Import-Module "${env:ProgramFiles(x86)}\Microsoft Dynamics NAV\90\RoleTailored Client\Microsoft.Dynamics.Nav.Model.Tools.psd1"

Set-Location $workFolder
New-Item -Name $release -ItemType directory -ErrorAction Stop
Set-Location $release
# export release files
Import-NAVServerLicense $devNavinstance -LicenseFile "$workFolder\HAT_Licence.flf" -Force -ErrorAction Stop
Write-Progress -Activity "DEV objektide eksport"
cmd /c """""${env:ProgramFiles(x86)}\Microsoft Dynamics NAV\90\RoleTailored Client\finsql.exe"" command=exportobjects,servername=$ServerName,database=$DevDB,file=$release.txt,filter=Version List=$releaseObjectFilter""" 
cmd /c """""${env:ProgramFiles(x86)}\Microsoft Dynamics NAV\90\RoleTailored Client\finsql.exe"" command=exportobjects,servername=$ServerName,database=$DevDB,file=$release.fob,filter=Version List=$releaseObjectFilter"""
Import-NAVServerLicense $devNavinstance -LicenseFile "$workFolder\Cust_licence.flf"

New-Item -Name 'origFiles' -ItemType directory
New-Item -Name 'devFiles' -ItemType directory
Split-NAVApplicationObjectFile -Source $release'.txt' -Destination 'devFiles' 
$highestObjNo = 0
$lowestObjectNo = 100000000
$separateFilter = ""
$i = 0
ForEach ($file in (Get-ChildItem -Path devFiles\) ){       
    $currObjNo = [convert]::ToInt32($file.BaseName.SubString(3))
    if ($highestObjNo -lt $currObjNo) { $highestObjNo = $currObjNo }
    if ($lowestObjectNo -gt $currObjNo){ $lowestObjectNo = $currObjNo }    
    if(! [string]::IsNullOrEmpty($separateFilter))
    {
       $separateFilter += "|"
    }
    $separateFilter += $currObjNo
    $i++
}


#Write-Output """""${env:ProgramFiles(x86)}\Microsoft Dynamics NAV\90\RoleTailored Client\finsql.exe"" command=exportobjects,servername=$ServerName,database=$LiveDb,file=TEST.txt,filter=ID=$lowestObjectNo..$highestObjNo""" 
Import-NAVServerLicense $liveNavinstance -LicenseFile "$workFolder\HAT_Licence.flf" -Force -ErrorAction Stop
if ($i -gt 50)
{
    # too many objects, use range filter
    Write-Verbose "$lowestObjectNo .. $highestObjNo" -Verbose 
    cmd /c """""${env:ProgramFiles(x86)}\Microsoft Dynamics NAV\90\RoleTailored Client\finsql.exe"" command=exportobjects,servername=$ServerName,database=$LiveDb,file=TEST.txt,filter=ID=$lowestObjectNo..$highestObjNo"""  #,logfile=log.txt
}
else
{
    Write-Verbose $separateFilter -Verbose
    cmd /c """""${env:ProgramFiles(x86)}\Microsoft Dynamics NAV\90\RoleTailored Client\finsql.exe"" command=exportobjects,servername=$ServerName,database=$LiveDb,file=TEST.txt,filter=ID=""$separateFilter"""""  #,logfile=log.txt
}
Import-NAVServerLicense $liveNavinstance -LicenseFile "$workFolder\Cust_licence.flf"

Split-NAVApplicationObjectFile -Source 'TEST.txt' -Destination 'origFiles' 
# keep only changed live files
$NoOfFiles = (Get-ChildItem origFiles\ |Measure-Object).Count
$i = 0
ForEach ($file in (Get-ChildItem -Path origFiles\) ){    
    if (-not ( Get-ChildItem devFiles\ | Where-Object {$_.Name -match $file.Name}))
    {        
        $file.Delete()
    }
    $i++
    Write-Progress -Activity "test failide kontroll . . ." -PercentComplete(($i / $NoOfFiles)  * 100)
}
Remove-Item 'TEST.txt'

# create zip
Set-Location ..
Add-Type -Assembly System.IO.Compression.FileSystem 
$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
[System.IO.Compression.ZipFile]::CreateFromDirectory($workFolder+$release,$workFolder+$release+'.zip', $compressionLevel, $false)