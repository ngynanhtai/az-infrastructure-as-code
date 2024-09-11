# Building a Web Server in Azure

## Introduction
In this project, you will use Terraform to create infrastructure as code to deploy a website with a load balancer, and Packer to build the image.

## Getting Started
Before you start deploying a Web Server in Azure, you will need:
- An Azure Account
- An installation of the latest version of [Terraform](https://developer.hashicorp.com/terraform/install)
- An installation of the latest version of [Packer](https://developer.hashicorp.com/packer/install)
- An installation of the latest version of the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/)

## Dependencies
Before you start deploying a Web Server in Azure, you will need:
- You can find all of the starter code for this project at this [Github repo](https://github.com/udacity/nd082-Azure-Cloud-DevOps-Starter-Code/tree/master/C1%20-%20Azure%20Infrastructure%20Operations/project/starter_files).

## Instructions
Once you've collected your dependencies, let's begin:
### 1. Creating a Policy
- Login to Azure using Azure CLI command:
	```
	az login
	```
- Create your project folder in your drive and open with command prompt
- Create a `tagging-policy.json` file and define your rule to `deny the creation of resources that do not have tags`
- Create policy definition by command:
	```
	az policy definition create --name ${policy_name} --subscription ${subscription_id} --mode Indexed --rules ./policy/tagging-policy.json
	```
- Assign policy to your current subscription by command:
	```
	az policy assignment create --name ${assignment_name} --policy ${policy_name} --scope ${scope}
	```
	
### 2. Creating a Packer image
- Download Packer template from [Github repo](https://github.com/udacity/nd082-Azure-Cloud-DevOps-Starter-Code/blob/master/C1%20-%20Azure%20Infrastructure%20Operations/project/starter_files/server.json)
- Create a service principal with contributor role and limit the scope within your current subscription 
	```
	az ad sp create-for-rbac --role contributor --name ${principal_name} --scopes /subscriptions/${subscription_id}/resourceGroups/${resource_group_name}
	```
- Put credential values that return from the command above to your packer template
- Put your resource group that already applied policy above to this packer template
	```
	managed_image_resource_group_name = ${your_resource_group_name}
	```
- Use an `Ubuntu 18.04-LTS SKU` as your base image
- Set the location closest to you to reduce latency
- Create an image by command:
	```
	packer build ./packer/server.json
	```
	
### 3. Creating a Terraform file
- Create the infrastructure code by Terraform include:
    ```
    [ ] Your existing resource group
    [ ] A Virtual Network
    [ ] A Subnet
    [ ] A Network Security Group (allow access to other VMs and deny direct access from internet)
    [ ] A Network Interface
    [ ] A Public IP
    [ ] A Load Balancer
    [ ] A Virtual Machine Availability Set
    [ ] A Virtual Machine (using Packer image)
    [ ] Managed disks
    ```
- Define a `variables` file to configure your reuse variables
- Run `init` command to download the dependencies that defined in `providers`:
	```
	terraform -chdir=terraform init
	```
- Run `plan` command to create an execution plan, which lets you preview the changes that Terraform plans to make to your infrastructure.
    ```
    terraform -chdir=terraform plan -out solution.plan
    ```
- After preview the changes will make, run `apply` to execute the plan and deploy our infrastructure on Azure
    ```
    terraform -chdir=terraform apply solution.plan
    ```
## Output
    [x] A Web Server in Azure within a resource group that deny to create any resource without tag
    [x] 2 Virtual Machines created by Packer image with managed disks
    [x] An Availability Set
    [x] A Network Interface
    [x] A Public IP
    [x] A Network Security Group which allows access from other VMs on the subnet and deny direct access from the internet
    [x] A Load Balancer
