<img src="/assets/listusers.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

# Lightweight Directory Access Protocol (LDAP) with LDS via the Power Platform  
This repo lays out everything you need to 
1) Deploy an instance of Active Directory LDS (Lightweight Directory Services) on an Azure Virtual Machine.
2) Deploy and configure an Azure Automation Account to interact with this instance of LDS via PowerShell Runbooks.
3) How to build and configure a canvas Power App to provide a modern, customisable and feature-rich GUI for LDAP user, group and role administration, also using Microsoft Dataverse, via Azure Key Vault.
4) How to build and configure Power Automate flows which, triggered from the Power App, execute Runbooks to apply updates and changes to the LDS instance.
5) Log Analytics and dashboarding for your LDS instance in Power BI (coming soon)

In this repo, I am showing you how to deploy the required Azure services via Azure Portal, so that you are able to understand the configuration selections in human-friendly screenshots, rather than pages of Terraform/ARM/BICEP code which are overwhelming to navigate. Of course, all services deployed and configured can be achieved via pipeline deployment using any of the aforementioned template deployment methods. 

## Contents

 - [Deploying the Virtual Machine](#deploying-the-virtual-machine) 
 - [Deploying the LDS instance on the Virtual Machine](#deploying-the-lds-instance-on-the-virtual-machine)
 - [ADSI Edit configuring your LDS instance](#adsi-edit-configuring-your-lds-instance)
 - [Deploying an Azure Automation Account](#deploying-an-azure-automation-account)
 - [Create a Dataverse table and Service Principal for data snapshots of your LDS instance](#create-a-dataverse-table-and-service-principal-for-data-snapshots-of-your-lds-instance)
 - [Creating your automation Runbooks](#creating-your-automation-runbooks)

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

16) Select 'Yes, create an application directory partition' and give a partition name. It is recommended that you do this at the 'DC' level, rather than the 'CN' level; so consider this to be your top-level domain partition. **Note: Ensure you copy the directory partition you type here, as we will need it later.**
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

Your LDS instance is now fully deployed. Next, we will configure it by creating new containers, partitions, groups etc.

## ADSI Edit configuring your LDS instance

ADSI Edit (Active Directory Service Interfaces Editor) is a Microsoft Management Console (MMC) snap-in tool that allows administrators to view and edit the objects and attributes in an Active Directory (AD) environment. It provides low-level access to the directory service and is often used for tasks that cannot be performed using the standard Active Directory tools.

1) On your server, navigate to Windows Administrative Tools > ADSI Edit
<img src="/assets/ADSI%201.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

2) Under the Actions pane on the right-hand side, click 'More Actions' and select 'Connect to'
<img src="/assets/ADSI%202.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

3) Give your new LDS instance a friendly name; here, I have just called it 'LDS Instance' but you might want to call it something more unique. For 'Connection Point', select 'Select or type a Distinguished Name or Naming Context' and enter the partition path you created in step 16 above. For 'Computer', use the 389 port, by typing 'localhost:389'. Click OK.
<img src="/assets/ADSI%203.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

4) Your LDS instance will appear like below. 
<img src="/assets/ADSI%204.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

5) Double click it, and then double click the automatically created 'container', until you see the below. By default, a Roles container, an NTDS Quotas class and a LostAndFound class will have been created.
<img src="/assets/ADSI%205.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

6) Right click in the whitespace below 'CN=Roles' and select New > Object. Select the 'container' type and click Next. Give this the Value of 'Groups'; this will become the container for the Groups you want to set up. 
<img src="/assets/ADSI%206.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

7) Click Next. Here, you can simply click Finish. Alternatively, you can provide many more attributes you want to assign to this container, by clicking 'More Attributes'.
<img src="/assets/ADSI%207.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

8) If you click More Attributes, you can select the one you want to amend and type is value in the Edit Attribute field. You can edit as many as you like. Click Finish.
<img src="/assets/ADSI%208.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

9) You will see your new container now on your LDS instance. Repeat steps 6 to 8 to create containers, groups etc. I have created the below for now.
<img src="/assets/ADSI%209.png?raw=true" alt="LDS 1" title="LDS 1" width="60%">

Your LDS instance is now set up. But don't worry, you can always change, add or delete containers, partitions, groups etc, through ADSI Edit.

## Deploying an Azure Automation Account

1) In Azure Portal, use your existing Resource Group where your Server VM is, or create a new one.
2) From the Marketplace, search for 'Automation' and select it.
3) Give your Automation Account a name. Ensure that the account is being deployed into the same region as your Server VM; here, I always use UK South.
4) In the Advanced blade, ensure that System assigned is ticket under Managed Identities.
5) Under the Networking blade, you can configure the Automation Account to run under Public or Private Access. For Private Access, you will be asked to create a new Private Endpoint. For this solution, I am allowing Public access. All this means is that public IP addresses are allowed to try to connect to the Automation Account, not that the Automation Account is literally open for public use.
6) Click 'Review + Create'
7) Wait for your Automation Account to deploy. This can take up to 10 minutes.

## Create a Dataverse table and Service Principal for data snapshots of your LDS instance

Communicating via Runbooks to your LDS instance on your Server VM is fast and, unless you execute Runbooks against it extremely frequently, is a free model. However, whilst fast, it is not immediate and, when we look at the Power App later on, you will want a snapshot of the recent state of LDS Users which can be queried more effectively, plus, which can be used in dashboarding in Power BI. 

1) Navigate to a Power Apps environment to which you have System Administrator permissions.
2) Create a new Dataverse table called whatever you like.
3) Create Text columns for the properties which you will want to display in the List Users function of your Power App. For example, this could be Username, Email, Company and Group Memberships, and these are the four key attributes which I use in this solution, but you can create as many as you like.
4) In Azure Portal, go to Application Registrations and create a new Application Registration. Give this a meaningful name (e.g. 'LDS Dataverse Service Principal') and click Register.
5) Under the Manage blade, select 'Certificates and secrets'.
6) Click '+ New client secret', enter a description, and select the expiry time for this secret. Click Add.
7) **Copy the Value of the newly created secret and paste this somewhere safe for the time being - if you do not copy it now, you will not be able to get it again later**
8) Click the 'API permissions' blade, and select '+ Add a permission'.
9) Select 'Dynamics CRM' under the Microsoft APIs tab, and check the user_impersonation permission.
10) Click 'Add permission'
11) If required, click 'Grant admin consent for...' (you should not need to do this for this permission, but, if you do and cannot click this button, you must ask a Global Administrator to consent to this permission).
12) Click the Overview blade, and copy the Application (client) ID, and the Directory (tenant) ID, and paste them alongside your secret's Value for now. 
13) In Power Platform Admin Centre, select the environment where you created your Dataverse table.
14) Under 'Users', click 'See all'
15) At the top, select 'app users list'
16) Click '+ New app user'
17) In the flyout, select '+ Add an app' and select the Service Principal you have just created.
18) Select the business unit (the default one)
19) Under Security roles, click the pencil icon and select the Basic User, and, System Customizer, security roles.

## Creating your automation Runbooks

This solution uses PowerShell 5.1.

1) Navigate to your Automation Account, and select Runbooks under the Process Automation blade.
2) Select '+ Create a Runbook'
3) Give your runbook a name - for example 'List all LDS users'.
4) Under Runbook Type, select PowerShell
5) Under Runtime version, select 5.1.
6) Click 'Review + Create' and then 'Create'
7) You will be presented with a blank runbook. For now, you can leave this as-is.

8) You now need to associate your Server VM with the Automation Account so that Runbooks which are executed are taken on the Server VM itself; this is known as a Hybrid Worker model.
9) Click 'Hybrid worker groups' under the Process Automation blade.
10) Click '+ Create hybrid worker group'
11) Give the group a name (e.g. LDAPHybridGroup)
12) You can choose either Default or Custom, relating to 'Use Hybrid Worker Credentials'. If you choose 'Custom', you must provide the credentials which your Runbooks will run under on the Server VM.
13) On the 'Hybrid Workers' tab, click '+ Add Machine' and select your Server VM. Click Review + Create, and then Create. 
14) The Hybrid Worker extensions needed to run tasks on the Server VM are now automatically deployed. 

Here are some Runbooks I have written for the most common actions we will want our Power App to be able to 'execute':

1) [List all LDS Users](listldsusers.ps1)  - this Runbook lists all LDS users (Username, Email, Company and Group Memberships) and snapshots them into a Dataverse table, for fast and easy visualisation in-app and via dashboard. The Dataverse authentication credentials are never exposed in code; rather, they are utilised at runtime from the Azure Key Vault.
2) [Add a new user](createuser.ps1)  - this Runbook adds a new User to the LDS, using the input of Username, Email, Company and Group Membership, but can be customised to add additional parameters and attributes. 
3) Delete a user - this Runbook 'deletes' a User on the LDS, by moving their account to a 'Deleted Users' container.
4) Unlock a user account - this Runbook unlocks a specific User on the LDS, and returns success output to the app.
5) Reset a user account password - this Runbook resets a User password to a randomly-generated string of characters and numbers, and returns them to the administrator in the app. 



