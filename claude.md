AL-Development-Guidelines
A wiki repo containing guidelines for how we setup, develop, and maintain AL code repositories.

Creating new repositories
When creating new AL-code repositories, one should use the ALGO for GitHub repository template from microsoft:

PTE App template
Appsource App template
Use the "Use this template" button to create a new repository within this Github organization (Owner: kbsbc).

Check the Scenarios in the AL-Go repo to understand how to setup new apps in the repository, or register customer environments for CI/CD.

Development
Setting up Visual Studio Code for AL development
Install VSCode
Install Git and setup git global user.name and user.email
Install AL Extension Pack for VSCode
There exist an additional inhouse dev tool for VSCode, which makes setting up some default knowit specific task easier. You can find the latest version here (under releases).
You are now ready to develop Business Central extensions with VSCode!

Setup Git global user.name and user.email
git config --global user.name "Your Name"
git config --global user.email "Your.Name@kbsno.no"
Repository structure
When the repository has been created with the template specified above, you may add apps within direct subfolders in the repo:

Repository structure

Object naming convention and suffix
AL objects (Tables, Pages, Codeunits..) Should follow the same naming structure as standard objects from Microsoft, but including a KBS suffix at the end:

table 77500 "Some Table Name KBS" 
{
    ///...
}
Object ranges
All PTE apps that are customer specific (not shared between tenants) are to use the range:

62100 - 63000
For PTE apps that are shared between customers, find a range below that are not in use:

75000 - 79999
Test apps dependent upon internal apps

70000 - 74999
Current list of shared PTE apps (Contiunually update this list when creating new applications)

Application	ID range from	ID range to	Test ID range from	Test ID range to
Axia Frakt	77500	77529		
EHF Order	77540	77639	*****	*****
BC DevOps Client - Rapid Watch Support	77640	77659	*****	*****
RIHUB Integration Core	77680	77719	*****	*****
KIBS Finance Extensions	77720	77749	72720	72749
Address Master Connect	77750	77800	*****	*****
BC Log Analytics Query Client - Rapid Watch Telemetry	77820	77859	*****	*****
Pris Kalkulasjon (Grossist)	77870	77950	*****	*****
Gold Exchange	77960	77979	*****	*****
UnivarsalLabelPrint	77980	78010	*****	*****
DAM Integration	78020	78099	*****	*****
Inkasso.	78100	78149	*****	*****
PDF Merge	78160	78169	*****	*****
ContiniaAddon	78180	78199	*****	*****
FileMule	78300	78329	*****	*****
RedAlert	78400	78449	*****	*****
OrderApi	78500	78519	*****	*****
ProcessManual	78550	78579	*****	*****
Kbs.Test	78580	78599	*****	*****
EDocument	78800	78899	*****	*****
App folder structure
All source code within an appfolder should be placed inside a folder with the name of the Business Central object type, which itself should be placed within a "Src" folder.

For example for a table object the folder structure should look like this:

AppFolder/Src/Table/Tablename.Table.al
Or for a page extension:

AppFolder/Src/PageExt/PageExtensionName.PageExt.al
Code Cops
You should have these AL analysers active when developing in VS Code:

CodeCop
UiCop
PTE-Cop
PTE-Cop can be switched out with AppsourceCop if developing appsource apps.

You can enable and disable different Cops close to the bottom of VSCode:

Code Cops

App.json
Publisher
Knowit Insight Business Solution AS

logo
Knowit logo

Production Application Insights Connection String
InstrumentationKey=6605d28d-5f39-40a1-816f-7cd0fd8a6ebc;IngestionEndpoint=https://norwayeast-0.in.applicationinsights.azure.com/;LiveEndpoint=https://norwayeast.livediagnostics.monitor.azure.com/

This is to be used when an application is released to a customers production environment.

Customer Environment Application Insights Connection String
InstrumentationKey=c543e692-4ff8-4185-b047-42b5d38b360d;IngestionEndpoint=https://norwayeast-0.in.applicationinsights.azure.com/;LiveEndpoint=https://norwayeast.livediagnostics.monitor.azure.com/

This connection string should be used to capture Environment telemetry in a customer environment, should the customer want this telemetry service. The connection string is used within the customer's Admin Center.

API publisher
When developing custom API's use knowit in lowercase as the API publisher.

Cloning repositories from GitHub
To clone a repository from GitHub to your local machine, go to the relevant GitHub repo and click on the <> Code button:

Cloning in GitHub

Either copy the https link and clone the repo into a local folder using a terminal:

git clone your/repo/URL.git
Or you can use the Open with Visual Studio button.

Linking GitHub Pull Requests to DevOps Work Items
We are using DevOps for project and support management. It is therefore important to be able to link work done in GitHub with the relevant work items in DevOps.

Setting up DevOps Project link to GitHub Repository
For each DevOps project, one project member must create the link between the project and repository. This is done in the Project settings within a DevOps project. Inside the project settings, go to GitHub connections, and then new connection: DevOps Project GitHub Connections Continue with Connect your GitHub account, and log in. Select kbsbc as the organization you wish to connect. Finally, select the repositories you wish to connect to the DevOps project.

Performing a GitHub Pull Request linked to a DevOps Work Item
When finishing up with a feature, bug, or any other change to the source code, we should perform a pull request from the respective development branch into the main branch (Note: if CI/CD is setup for the repository, a new version of the app will be released to any Sandbox Environments registered in GitHub, if using default branch rules!). To Create a pull request in GitHub, go to the Pull reqests tab in the repository: GitHub Pull requests page When choosing the name of the pull request include an Azure Boards (DevOps) link by writing:

AB#{DevOpsWorkItemID}
For example if we want to link to a DevOps work item with ID = 45, we could use the GitHub pull request title: "Added feature to solve xyz requirement AB#45"

This work item link will also work with commit messages, if you wish to link a spesific GitHub commit to a DevOps work item.

Continuous Integration / Continuous Delivery (CI/CD)
Use the Scenarios to understand how to use the template to its fullest potential.

Prerequisite 1: Register AAD/Entra ID app in Customer Tenant
When setting up CI/CD for a customer in either a Sandbox or Production environment, you need to have a App Registration which have the required permissions to be able to push new versions of the app to the environments.

Register a new app
Log in to the customer tenant into Azure AD/Entra ID, and open App registrations:

Entra ID app reg

Click New Registration, and choose Single tenant (Accounts in this organizational directory only) for account type. Create the app registration.

Redirect URI can be left blank.

Note the Application (client) ID GUID, You need this for later:

App registration overview

Then open Certificates & Secrets, and click on New client secret with a expiry period you specify. Note the Value of the newly created secret, you will need it later.

Finally go to API permissions. Click on Add a permission, then find Dynamics 365 Business Central, Application permissions, and check

AdminCenter.ReadWrite.All
API.ReadWrite.All
Automation.ReadWrite.All
Press Add permissions. The final step is then to Grant admin consent for <Tenant>

Register the AAD app in the customers BC environment
Go to the Business Central environment you wish to publish apps from GitHub to. Then Search for AAD (Azure Active Directory Applications). Create a new record, and paste the application (client) id from the step earlier into the Client-ID field. Add a meaningful description. Set the status to Active.

Next add the D365 AUTOMATION, and the EXTEN. MGT. - ADMIN permission sets to the user permission sets list.

The Business Central Environment is now ready for CI/CD from GitHub.

Register a customer environment for CD in GitHub
Follow the instructions as specified in this scenario.

Remember, the first word in the Environment name in GitHub must match the customer's BusinessCentral environment name.

This means the GitHub Environment "Sandbox Test ABC" will map to the BC environment "Sandbox". If you are setting up a Production environment, remember to include "Production" somewhere in the GitHub environment name to tell GitHub that this is a production environment.

You need to configure an Environment Secret named AUTHCONTEXT to enable GitHub to deploy the built apps to the BC envrionments. Here is the Environment Secret template you should use to authenticate GitHub to the BC environment: {"TenantID":"YourTenantID","ClientID":"YourClientID","ClientSecret":"YourClientSecret"}