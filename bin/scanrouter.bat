@echo off
REM -------------------------------------------
REM brodsky@splunk.com 29OCT20
REM figures out the local default gateway and nmap scans it for delivery of data via XML to Splunk
REM delivers data into two files: $COMPUTERNAME_default_gw_output.log and $COMPUTERNAME_$DEFAULTGW.xml
REM these files then read by monitor stanzas
REM requires nmap CLI for windows - see the readme
REM -------------------------------------------

setlocal EnableDelayedExpansion

REM find the default gateway
@For /f "tokens=3" %%* in (
    'route.exe print ^|findstr "\<0.0.0.0\>"'
) Do @Set "DefaultGateway=%%*"

REM find the mac address of the gateway
@For /f "tokens=2" %%* in (
    'arp.exe -A %DefaultGateway% ^|findstr "dynamic"'
) Do @Set "MAC=%%*"

REM find the DNS 
@For /f "tokens=2 delims=:" %%f in (
    'echo exit^|nslookup 2^>nul'
) Do @Set "DNS=%%f" ) 
set "DNS=%DNS: =%" 

REM find the external IP address
@For /f %%i in ('curl http://ipinfo.io/ip') do @Set "IP=%%i"

REM find the external AS
@For /f "tokens=*" %%i in ('curl http://ipinfo.io/org') do @Set "ORG=%%i"

REM find the IP location
@For /f %%i in ('curl http://ipinfo.io/loc') do @Set "LOC=%%i"

REM find the Network Category
@For /f "usebackq tokens=2 delims=:" %%f in (
    `powershell Get-NetConnectionProfile ^| findstr NetworkCategory`
) Do @Set "CATEGORY=%%f" ) 
set "CATEGORY=%CATEGORY: =%" 

REM find the Name
@For /f "usebackq tokens=2 delims=:" %%f in (
    `powershell Get-NetConnectionProfile ^| findstr Name`
) Do @Set "NAME=%%f" ) 
set "NAME=%NAME: =%" 

echo %date% %time% external_ip="%IP%" default_gateway="%DefaultGateway%" DNS="%DNS%" gateway_mac=%MAC% reporting_host="%COMPUTERNAME%" org="%ORG%" loc="%LOC%" network_category="%CATEGORY%" name="%NAME%" >> "%SPLUNK_HOME%\etc\apps\TA-hrs\bin\monitor\%COMPUTERNAME%_default_gw_output.log"

if exist "%SPLUNK_HOME%\etc\apps\TA-hrs\bin\output\%COMPUTERNAME%_%DefaultGateway%.xml" (
	copy "%SPLUNK_HOME%\etc\apps\TA-hrs\bin\output\%COMPUTERNAME%_%DefaultGateway%.xml" "%SPLUNK_HOME%\etc\apps\TA-hrs\bin\monitor\%COMPUTERNAME%_%DefaultGateway%.xml"
	)

REM if a Private network then run an nmap scan
REM MODIFY the below (Frothly_WFH) to match your deployed network WFH profile
if %CATEGORY%==Private IF %NAME%==Frothly_WFH (
     "%SPLUNK_HOME%\etc\apps\TA-hrs\bin\nmap\nmap.exe" -oX "%SPLUNK_HOME%\etc\apps\TA-hrs\bin\output\%COMPUTERNAME%_%DefaultGateway%.xml" -A %DefaultGateway%
     ) else (
     echo "Public network, and/or network name does not match, no nmap scan will occur, exiting..."