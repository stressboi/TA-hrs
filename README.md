TA-hrs
2NOV2020
brodsky@splunk.com

WARNING: The use of this TA *will* create significant data privacy concerns. By using it, you will potentially scan the default gateway currently in use by a corporate-owned endpoint. While this endpoint should theoretically be the "work from home" router that is in use by your employee, if you do not take precautions, it could just as easily be the router at the local coffeehouse, or at Grandmas. I have designed several failsafes into the logic but none of them are foolproof. These failsafes are: 1) the script only scans the gateway if the Network Category is set to "Private" and 2) it only scans if the Name is set to "Frothly_WFH" -- obviously you would want to set this to whatever the Name is fo the connection profile you have set up for your work-from-home users.

Regardless, you will be retrieving metadata about the egress device of your work-from-home users, and this may or may not be legal. Please see the advice of your DPO before running this in production!

----

This is a TA designed to run on a Windows 10 endpoint that is also running the Splunk Universal Forwarder. If you provide it with a local copy of the Windows nmap CLI tools, it will, at the prescribed interval in inputs.conf...

-Determine the current default gateway IP address
-Determine the MAC address of that IP from the local ARP table
-Determine the Network Category of the active connection
-Determine the current DNS server
-Determine the external IP address, AS, and IP location of the endpoint (via ipinfo.io)

It then reports all of this information via key-value pairs into a local log file (%COMPUTERNAME%_default_gw_output.log) which is monitored by an entry in the inputs.conf, and deposited into Splunk, e.g.:

Mon 11/02/2020 16:41:16.23 external_ip="73.217.129.100" default_gateway="192.168.10.1" DNS="75.75.75.75" gateway_mac=aa-bb-cc-11-22-33 reporting_host="MY_ENDPOINT" org="AS7922 Comcast Cable Communications, LLC" loc="39.8700,-104.9300" network_category="Private" name="Frothly_WFH"

If the following conditions are met:

-Network Category is set to "Private"
-Network Name is set to "Frothly_WFH"

...an nmap scan will be generated against the found gateway IP address, and those results will be placed into a local log file (%COMPUTERNAME%_%DefaultGateway%.xml) which is monitored by an entry in the inputs.conf, and deposited into Splunk in XML format.

The option exists for the nmap scan to *also* do OS fingerprinting.

Pre-requisites

1) Recent version of Splunk Universal Forwarder running on a Windows 10 endpoint. This is NOT designed to run on a server.
2) Windows 10 must have curl installed (most recent versions have this - type "curl" at a command line to check.)
3) You must download the recent nmap CLI distro for Windows and place it in the "nmap" directory under "bin" - this can be downloaded from https://nmap.org/dist/nmap-7.91-win32.zip.
4) You must install the 2013 Visual C++ Redistributables on the endpoint (this is in the nmap distro and is called "vcredist_x86.exe")
5) For OS fingerprinting support, install npcap on the endpoint (this is in the nmap distro and is called "npcap-1.00.exe")

Installation Instructions

1) Install UF on Windows endpoint, ensure it is reporting correctly into your Splunk instance.
2) Install this TA in TA-hrs on each endpoint (you can use the deployment server)
3) Make sure each endpoint has the nmap CLI distro in the "nmap" directory under "bin"
4) Make sure each endpoint meets the pre-reqs above. 
5) Copy inputs.conf into a new directory called "local" and make edits. You will want to enable one of the two scanrouter script entries (but not both). You may want to put the output into another directory besides "local."
6) Edit the scanrouter batch script you want to use, and find the line:

"REM MODIFY the below (Frothly_WFH) to match your deployed network WFH profile"

...and edit the line below it, replacing "Frothly_WFH" with the name of the network profile that should be scanned if it is found. NOTE! The name cannot have spaces in it!

(to change the network profile name, see this article: https://www.howtogeek.com/364291/how-to-change-or-rename-the-active-network-profile-name-in-windows-10/)

7) Edit the interval in the inputs.conf for the scanrouter script you have enabled and pick a proper interval. Once every day (86400) is default.

Troubleshooting

-Endpoint must be able to hit ipinfo.io
-Standard scripted input troubleshooting applies - check in _internal for output

Email brodsky@splunk.com with questions. Thanks!



