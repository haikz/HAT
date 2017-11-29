# updates ClientUserSetting ClientServicesKeepAliveInterval for all users
ForEach ($file in (dir -Path "C:\Users") ){  
    $path = 'C:\Users\'+$file.Name+'\AppData\Roaming\Microsoft\Microsoft Dynamics NAV\90\ClientUserSettings.config'  
    if([System.IO.File]::Exists($path)){
        $doc = [xml] (Get-Content $path)
        $obj = $doc.configuration.appSettings.add | where {$_.Key -eq 'ClientServicesKeepAliveInterval'}
        $obj.value = '1210'
        $doc.Save($path)
    }    
}