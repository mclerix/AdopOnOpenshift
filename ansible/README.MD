# Tower configuration for ADOP on OpenShift
This documentation aims to describe all the steps to configure tower to automate the deployment of ADOP for this demonstration.

Requirements:
* A tower instance up & running

The documentation is splitted in the following steps:

1. Project
2. Inventory
3. Job template

## 1. Project

In this section, we will create 2 projects for ADOP deployment and ASKME deployment.

* Click on **"Projects"** tab and then click on the button **"Add"** and fill the fields.
    ```
    SCM type: manual
    Name: ADOP deployment
    Organisation: Choose one depending on your Ansible Tower infrastructure
    ```

/!\ While using SCM type as manual, The `project base path` field will give you the repository on your Ansible Tower that will hosts the playbook for your projects. Copy the playbook available on this link within the directory: https://raw.githubusercontent.com/clerixmaxime/AdopOnOpenshift/master/ansible/adop/main.yml 

Once done, do the same thing for Askme:

* Click on "Projects" tab and then click on the button "Add" and fill the fields.
    ```
    SCM type: manual
    Name: ASKME deployment
    Organisation: Choose one depending on your Ansible Tower infrastructure
    ```
/!\ While using SCM type as manual, The `project base path` field will give you the repository on your Ansible Tower that will hosts the playbook for your projects. Copy the playbook available on this link within the directory:  https://raw.githubusercontent.com/clerixmaxime/AdopOnOpenshift/master/ansible/askme/main.yml

## 2. Inventory


### 2.1 Create inventory

The inventory list the machines that will be targeted to run the playbook. In this case, we will create an inventory with the OpenShift Master machine.

1. Creating the inventory
    * Click on **"Inventory"** tab, then click **"Add"**
    * Fill a Name (i.e. ADOP inventory), chose an organization and then click **"Save"**
2. Adding host
    * Click on the inventory that you previously created
    * Click on **"Add host"**, fill the hostname with the name of the openshift master machine. Also add a description (i.e. OpenShift Master)
3. Creating credentials
    * Click on **"Settings"** on the top right Corner, then select **"Credentials"**.
    * At this time, the configuration depends on how you access the openshift master machine. Make sure that you configure privilege escalation to gain sudo access. Let's say that you named your credentials adop-credentials

### 2.2 Test connectivity

In your inventory, check the box on the left of the host that you just created and then click on **"Run commands"** on the left. 

Select `shell` module, fill arguments with `ls` and select the credentials `adop-credentials`. Click on launch, Tower should execute a ls command on the machine, if it succeeds, you configuration is right.

## 3. Job template

The job template allows to configure what will be executed and on which machine. We have to create 2 job templates, 1 for ADOP and another one for ASKME.

**ADOP**
* Click on **"Templates"** tab
* Click on **"Add"**, then fill the field.
    * Name: ADOP Deployment
    * Description: ADOP deployment on OpenShift Container Platform 3.6 on Azure
    * Inventory: ADOP inventory (The one created before)
    * Project: ADOP deployment
    * Playbook: main.yml
    * Credentials: adop-credentials
    * Verbosity: Choose the one that fits your needs
    * Check "Enable privilege escalation"
    * Extra variables, add variables below
    ```yaml
    ---
    project_name: ''
    project_display_name: ''
    project_description: ''
    ```
    * Check "prompt on launch"

**ASKME**
* Click on **"Templates"** tab
* Click on **"Add"**, then fill the field.
    * Name: ADOP Deployment
    * Description: ADOP deployment on OpenShift Container Platform 3.6 on Azure
    * Inventory: ADOP inventory (The one created before)
    * Project: ADOP deployment
    * Playbook: main.yml
    * Credentials: adop-credentials
    * Verbosity: Choose the one that fits your needs
    * Check "Enable privilege escalation"
    * Extra variables, add variables below and check "prompt on launch"
    ```yaml
    ---
    app_name: ''
    project_name: ''
    ```
    * Check "prompt on launch"