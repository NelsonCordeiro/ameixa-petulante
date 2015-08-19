# ====================================================================
# Monitoring Windows Counters
# Author: Nelson Cordeiro
# mail: Nelson.unisys@br.unisys.com
# version 1.5
# ====================================================================
#
#	Performance Counters
#
#	Created by Nelson Cordeiro
#	06/02/2015
#
#	External's tag:
#		<load value='powershell32.exe -nologo -ExecutionPolicy bypass -NonInteractive -File "C:\Program Files (x86)\BBWin\bin\perfcounters.ps1" -tagName tagteste' />
#		<load value='powershell32.exe -nologo -ExecutionPolicy unrestricted -NonInteractive -File "C:\Program Files (x86)\BBWin\bin\perfcounters.ps1" -tagName tagteste' />
#			ou
#		<load value='powershell32.exe "perfcounters.ps1" -tagName sharepoint' />
#		<load value='powershell32.exe "perfcounters.ps1" iis' />
#	
#	The parameter "tagName" is the tag where are the especific configuration.
#	You can execute the same script more times setting different tagName's
#	
#	For example "perfcounters":
#
#    <perfcounters>
#		<setting name="\SharePoint Foundation(*)\Sql Query Executing  time" warnlevel="2" paniclevel="3" description="The average executing time of Sql queries" instances="_total,owstimer,hostcontrollerservice,noderunner" lessthan="true" />
#        <setting name="\SharePoint Foundation(*)\Executing Sql Queries" warnlevel="2" paniclevel="3" description="The number of current executing Sql queries" instances="_total,owstimer,hostcontrollerservice,noderunner" lessthan="true" />
#        <setting name="\SharePoint Foundation(*)\Responded Page Requests Rate" warnlevel="2" paniclevel="3" description="Number of requests responded in last second" instances="_total,owstimer,hostcontrollerservice,noderunner," />
#        <setting name="\SharePoint Foundation(*)\Executing Time/Page Request" warnlevel="2" paniclevel="3" description="Average executing time (in ms) for responsed requests in last seconds" instances="_total,owstimer,hostcontrollerservice,noderunner,distributedcacheservice,securitytokenserviceapplicationpool" />
#        <setting name="\SharePoint Foundation(*)\Current Page Requests" warnlevel="2" paniclevel="3" description="The number of current requests in processing" instances="_total,owstimer,hostcontrollerservice,noderunner,distributedcacheservice,securitytokenserviceapplicationpool" />
#        <setting name="\SharePoint Foundation(*)\Reject Page Requests Rate" warnlevel="2" paniclevel="3" description="The number of rejecting requests in last second" instances="_total,owstimer,hostcontrollerservice,noderunner,distributedcacheservice,securitytokenserviceapplicationpool" />
#        <setting name="\SharePoint Foundation(*)\Incoming Page Requests Rate" warnlevel="2" paniclevel="3" description="The number of incoming requests in last second" instances="_total,owstimer,hostcontrollerservice,noderunner,distributedcacheservice,securitytokenserviceapplicationpool" />
#        <setting name="\SharePoint Foundation(*)\Active Threads" warnlevel="2" paniclevel="3" description="The number of threads currently executing in SharePoint code" />
#        <setting name="testname" value="sql-server" />
#    </perfcounters>
#
#	Each settings have the especifc param: "warnlevel", "paniclevel", "description", "instances" and "lessthan"
#	Script will get all instances(*) if you do not put "instances" parameter
#
#	Set "lessthan" as 'true' when you want to monitor the value less than the threshold
#
#	Each counter path has the following format:
#	"[\\<ComputerName>]\<CounterSet>(<Instance>)\<CounterName>"
#	For example:
#	"\\Server01\Processor(2)\% User Time"
#	The <ComputerName> element is optional. If you omit it, Get-Counter uses the value of the ComputerName parameter.
#
################## Param, FUNCTIONS and Variables ##############################

Param(
  [string]$tagName
)

Function BuildReport($message, $testName, $reportName, $ttl)
{
	$date = get-date
	$message = "<h2><center>$date</center></h2>`n<h2><center>$ttl</center></h2>`n`n$message `n`n`n$Scriptversion"
	$status = checkStatus($message)
	& "$binPath\bbwincmd.exe" $bbdisplay status $reportname $testName $status $message
}

Function checkStatus ($msg)
{
	if ($msg.Contains("&red")){
		return "red"
	}elseif ($msg.Contains("&yellow")){
		return "yellow"
	}elseif ($msg.Contains("&green")){
		return "green"
	}else{
		return "clear"
	}
}

if (Test-Path "C:\Program Files (x86)\BBWin\etc\BBWin.cfg") {
	$binPath = "C:\Program Files (x86)\BBWin\bin"
	$etcPath = "C:\Program Files (x86)\BBWin\etc"
	$tmpPath = "C:\Program Files (x86)\BBWin\tmp"
}else {
	$binPath = "C:\Program Files\BBWin\bin"
	$etcPath = "C:\Program Files\BBWin\etc"
	$tmpPath = "C:\Program Files\BBWin\tmp"
}

################## /END FUNCTIONS ##############################

$Scriptversion = "perfcounters.ps1 version 1.5"

$hostname = hostname
$msg = ""
$msgError = ""
$msgCounter = "`n`n"

#Get configuration of bbwin.cfg file
$xml = [xml](get-content "$etcPath\BBWin.cfg")

#Get BBDISPLAY from bbwin.cfg
$bbdisplay = ($xml.configuration.bbwin.setting | ? {$_.name -eq "bbdisplay"}).value
if ( ($xml.configuration.bbwin.setting | ? {$_.name -eq "bbdisplay"}).value -eq $null) {
	$bbdisplay = "200.220.88.12"
}else{
	$bbdisplay = ($xml.configuration.bbwin.setting | ? {$_.name -eq "bbdisplay"}).value
}

#Get TITLE from bbwin.cfg
if ( ($xml.configuration.$tagName.setting | ? {$_.name -eq "title"}).value -eq $null) {
	$title = "Performance Counters"
}else{
	$title = ($xml.configuration.$tagName.setting | ? {$_.name -eq "title"}).value
}

#Get TESTNAME from bbwin.cfg
if ( ($xml.configuration.$tagName.setting | ? {$_.name -eq "testname"}).value -eq $null) {
	$bbtest = "perfcounters"
}else{
	$bbtest = ($xml.configuration.$tagName.setting | ? {$_.name -eq "testname"}).value
}

#Get all settings of tag except testname, ignore and title
$bbwinValues = $xml.configuration.$tagName.setting | ? {($_.name -ne "testname") -and ($_.ignore -ne "true") -and ($_.name -ne "title") }

$style = "style='font-size: 12;line-height: 17px;background-color: #1C1C1C;color: white;width: 40%'"
$style2 = "style='font-size: 12;line-height: 17px;background-color: #1C1C1C;width: 10%'"
$thresholds += "`n
<table border=1 style='width:1000px'>
	<tr>
		<td $style><center><b>Counter</b></center></td>
		<td $style><center><b>Description</b></center></td>
		<td $style2><center><b>Panic threshold</b></center></td>
		<td $style2><center><b>Warning threshold</b></center></td>
	</tr>"

$bbwinValues | % {
	
	if ( $(Get-Counter -Counter $_.name) -eq $null ) {
		$msgCounter += "`nCannot found the counter: " + $_.name
	}
	
	$counter = $_.name
	$warnthres = $_.warnlevel
	$panicthres = $_.paniclevel
	$Description = $_.description
	
	if ($_.instances -eq $null ){
		$allinst = $true
	}else {
		$allinst = $false
		$instances = $_.instances
	}
	
	$msg += "`n`n"
	
	if ($_.lessthan -eq "true"){
	
		$(Get-Counter -Counter $_.name).countersamples | % {
			$InstanceName = $_.InstanceName
			
			$counterpath = $_.path
			$arraypath = $counterpath -split "\\"
			$counterpath = "\" + $arraypath[4] + " (" + $InstanceName + ")"
			$Value = [math]::Round($_.cookedvalue,2)
			
			if ($allinst) {
				if ($Value -le $panicthres) {
					$msg += "&red $counterpath`t:$Value`n"
					$msgError += "&red $counterpath`t:$Value`n"
				}elseif ($Value -le $warnthres){
					$msg += "&yellow $counterpath`t:$Value`n"
					$msgError += "&yellow $counterpath`t:$Value`n"
				}else{
					$msg += "&green $counterpath`t:$Value`n"
				}
			}else{
				if ( $instances -match $InstanceName ){
				
					if ($Value -le $panicthres) {
						$msg += "&red $counterpath`t:$Value`n"
						$msgError += "&red $counterpath`t:$Value`n"
					}elseif ($Value -le $warnthres){
						$msg += "&yellow $counterpath`t:$Value`n"
						$msgError += "&yellow $counterpath`t:$Value`n"
					}else{
						$msg += "&green $counterpath`t:$Value`n"
					}
				}
			}
		}
	}else{
		$(Get-Counter -Counter $_.name).countersamples | % {
			$InstanceName = $_.InstanceName
			$counterpath = $_.path
			$arraypath = $counterpath -split "\\"
			$counterpath = "\" + $arraypath[4] + " (" + $InstanceName + ")"
			$Value = [math]::Round($_.cookedvalue,2)
			
			if ($allinst) {
				if ($Value -ge $panicthres) {
					$msg += "&red $counterpath`t:$Value`n"
					$msgError += "&red $counterpath`t:$Value`n"
				}elseif ($Value -ge $warnthres){
					$msg += "&yellow $counterpath`t:$Value`n"
					$msgError += "&yellow $counterpath`t:$Value`n"
				}else{
					$msg += "&green $counterpath`t:$Value`n"
				}
			}else{
				if ( $instances -match $InstanceName ){
				
					if ($Value -ge $panicthres) {
						$msg += "&red $counterpath`t:$Value`n"
						$msgError += "&red $counterpath`t:$Value`n"
					}elseif ($Value -ge $warnthres){
						$msg += "&yellow $counterpath`t:$Value`n"
						$msgError += "&yellow $counterpath`t:$Value`n"
					}else{
						$msg += "&green $counterpath`t:$Value`n"
					}
				}
			}
		}
	}
	
	
	#Thresholds table
	$thresholds += "
	<tr>
		<td ><center>$counter</center></td>
		<td ><center>$Description</center></td>
		<td ><center>$panicthres</center></td>
		<td ><center>$warnthres</center></td>
	</tr>"
	#tabela dos thresholds
}

$thresholds += "</table>`n`n"

$chkSts = checkStatus($msg)
if ( ($chkSts -eq "red") -or ($chkSts -eq "yellow") ){
	$msg = $msgError
}

$msg += $msgCounter + $thresholds

BuildReport $msg $bbtest $hostname $title

exit $Status
