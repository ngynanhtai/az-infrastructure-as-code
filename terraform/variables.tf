# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "number_vms" {
  description = "Number of VMs in this VMAS"
  default = 2
}

variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  type = string
  default = "udacity-demo"
}

variable "custom_port" {
  description = "The default application port"
  type = number
  default = 9000
}

variable "tagging_policy" {
  description = "The tag which should be used for all resources in this example"
  type = map(string)
  default = {
	Source = "udacity"
  }
}

variable "resource_group_name" {
  description = "This project resource"
  default = "udacity-demo-rg"
}

variable "packer_image" {
  description = "Image you use to build VMs"
  default = "udacity-demo-image"
}

variable "packer_image_rg" {
  description = "The resouce group name which stores packer Image"
  default = "udacity-demo-rg"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  type = string
  default = "eastasia"
  }

variable "admin_username" {
  description = "The admin username for the VM being created."
  type = string
  default = "ngynanhtai"
}

variable "admin_password" {
  description = "The password for the VM being created."
  type = string
  default = "Password@052105"
}