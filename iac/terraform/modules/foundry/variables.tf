variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "account_name" { type = string }
variable "chat_deployment_name" { type = string }
variable "chat_model_name" { type = string }
variable "chat_model_version" { type = string }
variable "chat_model_capacity" { type = number }
variable "tags" { type = map(string) }
