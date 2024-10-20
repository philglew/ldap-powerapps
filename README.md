<img src="/assets/listusers.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

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

3) You will be shown the below popup. You can click Next.
<img src="/assets/LDS%201.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

4) Select 'Role-based or feature-based installation'
<img src="/assets/LDS%202.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

5) Leave the destination server as-is, ensuring that your Server (the one you are working on) is selected.
<img src="/assets/LDS%203.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

6) Tick 'Active Directory Lightweight Directory Services', and the second pop-up box will appear. Check 'Include management tools (if applicable)' if not already selected, and click 'Add Features'
<img src="/assets/LDS%204.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

7) On the Select features screen, just click Next.
<img src="/assets/LDS%205.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

8) On the Confirmation screen, click 'Install'
<img src="/assets/LDS%206.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

9) Your LDS instance is installing, as per below.
<img src="/assets/LDS%207.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

10) When installed, you will see the below screen. You can click Close.
<img src="/assets/LDS%208.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

11) In Server Manager, click Tools > Active Directory Lightweight Directory Services Setup Wizard
<img src="/assets/LDS%209.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

12) The wizard will start. Click Next.
<img src="/assets/LDS%2010.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

13) For this solution, we are creating a brand new unique instance of LDS. If you wish to replicate an existing instance, select that option and follow the wizard through.
<img src="/assets/LDS%2011.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

14) Give your unique LDS instance a name and a description.
<img src="/assets/LDS%2012.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

15) Note the following window regarding ports. For this solution, we are leaving these as the default, as we will not be installing ADDS on this server. Click Next.
<img src="/assets/LDS%2013.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

16) Select 'Yes, create an application directory partition' and give a partition name. It is recommended that you do this at the 'DC' level, rather than the 'CN' level; so consider this to be your top-level domain partition. 
<img src="/assets/LDS%2014.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

17) In the File Locations screen, leave this as-is and click Next.
<img src="/assets/LDS%2015.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

18) In the Service Account Selection screen, choose 'This account'. Click Browse and enter your Administrator username and click 'Check'. Your username will be found. Enter the password for this account. This is the same username and password you used to log-onto the Server VM. Click Next.
<img src="/assets/LDS%2016.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

19) Select 'Currently logged on user...' and click Next
<img src="/assets/LDS%2017.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

20) On the importing LDIF files screen, ensure that the following are checked. These are needed later on in the solution, and to give you the ability to create Users on this LDS instance which, by default, is not possible unless we deploy the LDIF file for it now.
<img src="/assets/LDS%2018.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">
<img src="/assets/LDS%2019.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

21) On the Ready to Install screen, click Next
<img src="/assets/LDS%2020.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

22) The LDS instance will be installing and configuring
<img src="/assets/LDS%2021.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

23) When complete, click the Refresh icon in Server Manager, and your new AD LDS instance will appear like below.
<img src="/assets/LDS%2022.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

## ADSI

<img src="/assets/ADSI%201.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">
<img src="/assets/ADSI%202.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">
<img src="/assets/ADSI%203.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">
<img src="/assets/ADSI%204.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">
<img src="/assets/ADSI%205.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">
<img src="/assets/ADSI%206.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">
<img src="/assets/ADSI%207.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">
<img src="/assets/ADSI%208.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">
<img src="/assets/ADSI%209.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">




