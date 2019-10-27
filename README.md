# CM-CreateADBoundaryGroups
Script to create Boundary Groups for all AD Site based boundaries, so a list of Site System servers is assigned if a client roams in Active Directory

# Prerequisites
The script uses Configuration Manager CMDlets, so it needs to run on a machine with Configuration Manager console installed.

# Deployment
The script has two mandatory parameters:

CMSiteCode: Configuration Manager site code

CMProviderMachineName: Machine name of the Configuration Manager SMSProvider to be used by the script.

CMSiteSystemServers: Comma separated list of Site System Servers for autocreated Boundary Groups.

# License
This project is licensed under the MIT License - see the LICENSE.md file for details
