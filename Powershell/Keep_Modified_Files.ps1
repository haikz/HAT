Set-Location "C:\Compare_NAV" # work dir
$liveSource = "LIVE.txt";
$devSource = "DEV.txt";

powershell Set-ExecutionPolicy RemoteSigned
Import-Module "${env:ProgramFiles(x86)}\Microsoft Dynamics NAV\100\RoleTailored Client\Microsoft.Dynamics.Nav.Model.Tools.psd1"

if (Test-Path .\Modified) {
    Remove-Item C:\Compare_NAV\Modified\*    
}
else {
    new-item -Name 'Modified' -ItemType directory -ErrorAction Ignore    
}
if (Test-Path .\Original) {
    Remove-Item C:\Compare_NAV\Original\*    
}
else {
    new-item -Name 'Original' -ItemType directory  -ErrorAction Ignore
}

Split-NAVApplicationObjectFile -Source $liveSource -Destination 'Original' 
Split-NAVApplicationObjectFile -Source $devSource -Destination 'Modified' 

Get-ChildItem Original,Modified -recurse |
    get-filehash |
    Group-Object -property hash |
    Where-Object { $_.count -gt 1 } |   
    ForEach-Object {                         
        $_.group |              
        Select-Object 
       } |                       
    Remove-Item           