# Lightweight Directory Access Protocol (LDAP) via the Power Platform  
This repo lays out everything you need to 
1) Deploy an instance of Active Directory LDS (Lightweight Directory Services) on an Azure Virtual Machine.
2) Deploy and configure an Azure Automation Account to interact with this instance of LDS via PowerShell Runbooks.
3) How to build and configure a canvas Power App to provide a modern, customisable and feature-rich GUI for LDAP user, group and role administration.
4) How to build and configure Power Automate flows which, triggered from the Power App, execute Runbooks to apply updates and changes to the LDS instance.
5) Log Analytics and dashboarding for your LDS instance in Power BI.

In this repo, I am showing you how to deploy the required Azure services via Azure Portal, so that you are able to understand the configuration selections in human-friendly screenshots, rather than pages of Terraform/ARM/BICEP code which are overwhelming to navigate. Of course, all services deployed and configured can be achieved via pipeline deployment using any of the aforementioned template deployment methods. 

## Deploying the Virtual Machine

For LDS, it is advised that the minimum size of Azure VM is Standard_B2s. The VM must be deployed with Windows Server Datacenter; and the latest version (Windows Server Datacenter 2022) is used in this walkthrough. 

1) In Azure, navigate to your Subscription (you must be a Contributor, Owner or Administrator of the Subscription) and create a new Resource Group.
2) From the Marketplace, create a new Azure Virtual Machine.
3) In the Basics blade, the only specifics required for this deployment and solution are:
    a. Trusted launch enabled.
    b. Image: Windows Server 2022 Datacenter.
    c. VM architecture: x64
    d. Do not run with Spot discount.
    e. Size is up to you, but the minimum really is Standard_B2s (2 vcpus, 4 GiB memory)
    f. HTTPS and SSH enabled.
    g. Provide a local Administrator username and password for the virtual machine. 
5) In the Disks blade, this can be left as-is.
6) In the Networking blade, you can deploy this Virtual Machine inside an existing virtual network or configure a new one based on your requirements for networking. For this repo, we are allowing all IP addresses to connect to our virtual machine, and allowing ports 443 and 22.
7) In the Management blade, check "Enable system assigned managed identity" and check "Login with Microsoft Entra ID". It is recommended that you include this virtual machine in Microsoft Defender for Cloud.
8) In the Monitoring blade, select the options you would like.
9) In the Advanced blade, select any extensions, custom data or VM application you want to install as the virtual machine deploys. None are required for this solution.
10) Click 'Review + Create' and wait for your virtual machine to deploy.

11) When the Virtual Machine has finished reploying, go to the Virtual Machine resource and copy the Public IP address. 

12) Open Remote Desktop Connection on your computer, and logon to it using the Public IP and the Administrator username and password you set in Step 3g.

13) Wait for the initial launch of the Virtual Machine to configure.

## Deploying the LDS instance on the Virtual Machine

1) Server Manager should automatically load, but, if it doesn't, open Server Manager.

2) Select 'Manage' on the top right, and click 'Add/Remove Features'.

![LDS1](/assets/LDS%201.png?raw=true "LDS 1")

