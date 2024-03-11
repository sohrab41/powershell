param($runTime, $type)
if ($runTime -eq 1) 
{          
     $runProcess = "Morning " 
}
if ($runTime -eq 2) 
{          
     $runProcess = "Afternoon "
}

$title =" leverance "
#---- Process argument ----
$argList = "-$runTime --force --activate --duplicate-analysis -$type"

$logfile="D:\Ankiro\JobAdManagement\batch\log\leverancelog.txt"
Write-Output "">> $logfile

Write-Host "--------------start $runProcess $type Leverance-------------------"
Write-Output "--------------start $runProcess $type Leverance-------------------">> $logfile

$startTime=[datetime]::Now.Tostring('yyyy-MM-ddTHH:mm:ss')
#---- logfile ----
Write-Host "$type $runProcess $title  start run Time: $startTime in server $env:computername"
Write-Output "$type $runProcess $title start run Time at : $startTime in server $env:computername" >> $logfile
#---- Processfile ----
$path = "D:\Ankiro\Ankiro.GenerateLeverance\GenerateDelivery\"
$executable = "Ankiro.Ams.GenerateLeverance.exe"
$filePath = $($path)+$($executable) 
#---- zabbix exe file ----
$zabbixExeFile="c:\zabbix_agent\bin\zabbix_sender.exe"

Start-Process  $zabbixExeFile -ArgumentList "-z zabbix.ankiro.dk -s leverancesrv01.prod.ankiro.dk -o 0 -k SchTask.AMS.Leverance"		

$errorCount=0
While ($true){
     $p= Start-Process -FilePath   $filePath -ArgumentList $argList  -PassThru -Wait
     if($p.ExitCode -eq 1 ) {
          $errorCount++
          if($errorCount -ge 3 ) {
               Write-Host "Process failed 3 times Stopping running  errorCount : " $errorCount
               Write-Output "Process failed 3 times Stopping running  errorCount :  $errorCount" >> $logfile
               Send-MailMessage -From 'Ankiro <noreply@ankiro.dk>' -To 'hh <hh@ankiro.dk>' -Subject $runProcess $type' leverance Error!.' -Priority High -DeliveryNotificationOption OnSuccess, OnFailure -SmtpServer 'smtp.ankiro.dk'							
               Start-Process $zabbixExeFile  -ArgumentList "-z zabbix.ankiro.dk -s leverancesrv01.prod.ankiro.dk -o 1 -k SchTask.AMS.Leverance"		
               break;
          }
          Write-Host "Process failed " $errorCount " times, ExitCode : " $p.ExitCode  "Waiting five minutes and restart " $type $runProcess $title 
          Write-Output "Process failed $errorCount times, ExitCode: 1 Waiting five minutes and restart $type $runProcess $title " >> $logfile
          Start-Process $zabbixExeFile  -ArgumentList "-z zabbix.ankiro.dk -s leverancesrv01.prod.ankiro.dk -o 2 -k SchTask.AMS.Leverance"	
          Start-Sleep 5
       }
     else{
          $errorCount=0
          Start-Process $zabbixExeFile  -ArgumentList "-z zabbix.ankiro.dk -s leverancesrv01.prod.ankiro.dk -o 0 -k SchTask.AMS.Leverance"		
          Write-Host  "Process $type $runProcess $title  run successfully Exiting "
          Write-Output "Process $type $runProcess $title  run successfully Exiting" >> $logfile
          Break
     }
}
$endTime=[datetime]::Now.Tostring('yyyy-MM-ddTHH:mm:ss')
Write-Host "$type $runProcess $title  Process end Time at : $endTime"
Write-Output "$type $runProcess $title  Process end Time at: $endTime" >> $logfile