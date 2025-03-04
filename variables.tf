variable "cidr_block" {
  type = string
  default = "10.0.0.0/16"
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
  
}

variable "common_tags" {
  type = map(string)
  default = {}
}

variable "vpc_tags" {
  type = map(string)
  default = {}
  
}

variable "igw_tags" {
  type = map(string)
  default = {}
  
}

variable "public_cidr_block" {
	type = list(string)
    validation {
      condition = length(var.public_cidr_block) == 2
      error_message = "Public CIDR block should have 2 elements"
    }
}

variable "public_subnet_tags" {
  type = map(string)
  default = {}
  
}


variable "private_cidr_block" {
	type = list(string)
}

variable "private_subnet_tags" {
  type = map(string)
  default = {}
  
}


variable "database_cidr_block" {
	type = list(string)
}

variable "database_subnet_tags" {
  type = map(string)
  default = {}
  
}

variable "db_subnet_tags" {
  type = map(string)
  default = {}
  
}

variable "public_route_table_tags" {
  type = map(string)
  default = {}
  
}

variable "private_route_table_tags" {
  type = map(string)
  default = {}
  
}

variable "database_route_table_tags" {
  type = map(string)
  default = {}
  
}

variable "is_peering_required" {
  type = bool
  default = true
}