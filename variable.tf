# variables.tf

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
}

variable "replica_set_name" {
  description = "MongoDB replica set name"
  type        = string
}

variable "num_secondary_nodes" {
  description = "Number of secondary MongoDB nodes"
  type        = number
}

variable "mongo_username" {
  description = "MongoDB username"
  type        = string
}

variable "mongo_password" {
  description = "MongoDB password"
  type        = string
  sensitive   = true
}

variable "mongo_database" {
  description = "MongoDB database name"
  type        = string
}
