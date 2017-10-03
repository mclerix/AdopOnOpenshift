# CloudForms configuration for ADOP on OpenShift
This documentation aims to describe all the steps to configure CloudForms to provide a service catalog for the deployment of ADOP and AskMe for this demonstration.

The configuration of Cloudforms is divided as follow:
* Add Tower as automation provider
* Create a dedicated user for this demonstration
* Create and customise a Service Dialog
* Create a catalog

Requirements:
* Admin user on CloudForms
* Tower configuration done

## 1. Add Tower as automation provider
1. On the left panel go to `Automation > Ansible Tower > Explorer` 
2. Click on `Configuration > Add a new provider`
3. Fill the name for the provider, URL to access Ansible Tower, credentials and then click on "Add" button

## 2. Create a dedicated user and configure access control
1. Create a role 
    * On the top right, click on your admin user and then go to `Configuration > Access Control` Select "Roles" on the list and then click on `Configuration > Add a new role`
    * Call it "adop-user".
    * Uncheck all product features and just keep "Services" chacked. Click on "Add" button.
2. Create a tag
    * On the top right, click on your admin user and then go to `Configuration > Regions` Select your cloudforms region on the list and then click on "My Company Categories"
    * On the first line, in name type "adop" and in description "ADOP related tags" and click "Add" on the right
    * Go to "My Company Tags"
    * Select "ADOP related tags" as category and add tags adop and askme at the bottom.
3. Create a group
    * On the top right, click on your admin user and then go to `Configuration > Access Control` Select "Groups" on the list and then click on `Configuration > Add a new group`
    * Call it "adop"
    * Choose "adop-user" as Role
    * Choose "My Company" as tenant
    * Check all the tags within "ADOP related tags" in the tab "My Company Tags" and then click "Add"
4. Create a user
    * On the top right, click on your admin user and then go to `Configuration > Access Control` Select "Users" on the list and then click on `Configuration > Add a new user`
    * Call it "adop"
    * Choose "adop" as group
    * Fill with the password that you want

## 3. Create and customise a Service Dialog
### ADOP
1. Create Service Dialog
    * Go to `Automation > Ansible Tower > Explorer`. Expand `Job Templates > All ansible tower job templates > <YOUR_TOWER>` and select "ADOP deployment". Click on `Configuration > Create Service dialog from this job template`
    * Call it "ADOP deployment"
2. Customise the Service Dialog
    * Go to `Automation > Automate > Customization`. Expand `Service dialogs` and select "ADOP deployment". Click on `Configuration > Edit this Dialog`
    * Under `ADOP deployment > Basic Information > Extra Variables`, make sure 3 fields have been created with the following values:
        * Name
            * Label: Name:
            * Name: param_project_name
            * Type: text box
            * Uncheck "readonly" option
        * Display Name
            * Label: Display Name:
            * Name: param_project_display_name
            * Type: text box
            * Uncheck "readonly" option
        * Description
            * Label: Description:
            * Name: param_project_description
            * Type: text box
            * Uncheck "readonly" option
    * Once modifications are done, click on "Save"

### AskMe
1. Create Service Dialog
    * Go to `Automation > Ansible Tower > Explorer`. Expand `Job Templates > All ansible tower job templates > <YOUR_TOWER>` and select "AskMe deployment". Click on `Configuration > Create Service dialog from this job template`
    * Call it "AskMe deployment"
2. Customise the Service Dialog
    * Go to `Automation > Automate > Customization`. Expand `Service dialogs` and select "AskMe deployment". Click on `Configuration > Edit this Dialog`
    * Under `AskMe deployment > Basic Information > Extra Variables`, make sure 2 fields have been created with the following values:
        * Name
            * Label: App Name:
            * Name: param_app_name
            * Type: text box
            * Uncheck "readonly" option
        * Display Name
            * Label: Project Name:
            * Name: param_project_name
            * Type: text box
            * Uncheck "readonly" option
    * Once modifications are done, click on "Save"

## 4. Create a Service Catalog
1. Create Service Catalog
    * Go to `Service > Catalogs`. Click on "Catalogs" on the left list and then `Configuration > Add new catalog`.
    * Give it a name and description (i.e. ADOP / ADOP catalog)
    * Click on "Save"
2. Create Catalog Items for ADOP
    * Click on "Catalog Items" on the left list, select "ADOP" catalog and then `Configuration > Add new catalog item`.
    * Choose "Ansible Tower" as type 
    * Fill the information:
        * Name: ADOP
        * Description: ADOP Deployment Service
        * Check "Display in catalog"
        * Catalog: ADOP
        * Dialog: ADOP Deployment
        * Provider: The tower that you configured before
        * Ansible Tower Job Template: ADOP Deployment
    * Click on "Add"
    * Select the catalog item that you just created on the left pane, then click on `Policy > Edit tags` on the top.
    * In "Select a customer tag to assign", choose "ADOP related tags" and then "adop" and click on "Save" button. 
3. Create Catalog Items for AskMe
    * Click on "Catalog Items" on the left list, select "ADOP" catalog and then `Configuration > Add new catalog item`.
    * Choose "Ansible Tower" as type 
    * Fill the information:
        * Name: AskMe
        * Description: AskMe Deployment Service
        * Check "Display in catalog"
        * Catalog: ADOP
        * Dialog: AskMe Deployment
        * Provider: The tower that you configured before
        * Ansible Tower Job Template: AskMe Deployment
    * Click on "Add"
    * Select the catalog item that you just created on the left pane, then click on `Policy > Edit tags` on the top.
    * In "Select a customer tag to assign", choose "ADOP related tags" and then "askme" and click on "Save" button. 

Now, you should be ready to use CloudForms as a service catalog for the demonstration.