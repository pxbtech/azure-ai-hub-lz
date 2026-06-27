variable "location" {
  description = "Azure region for all resources. Pick a region where your chosen Foundry chat model is available."
  type        = string
  default     = "eastus"
}

variable "env_code" {
  description = "Environment code segment. Lowercase, 2 to 4 chars (e.g. dev, test, prod, poc)."
  type        = string
  default     = "poc"
  validation {
    condition     = length(var.env_code) >= 2 && length(var.env_code) <= 4
    error_message = "env_code must be 2 to 4 characters."
  }
}

variable "workload" {
  description = "Workload code segment. Lowercase, 3 to 6 chars."
  type        = string
  default     = "aihub"
  validation {
    condition     = length(var.workload) >= 3 && length(var.workload) <= 6
    error_message = "workload must be 3 to 6 characters."
  }
}

variable "org_code" {
  description = "Org / business unit code used in the resource group name."
  type        = string
  default     = "it"
}

variable "instance" {
  description = "Instance number, zero-padded. Used as the suffix on every resource name."
  type        = string
  default     = "01"
  validation {
    condition     = length(var.instance) == 2
    error_message = "instance must be exactly 2 characters."
  }
}

variable "budget_amount" {
  description = "Budget amount in the subscription billing currency, applied per billing cycle. Set whatever monthly cap you want enforced."
  type        = number
  default     = 2000
}

variable "budget_start_date" {
  description = "Budget start date. First of a calendar month, UTC, format YYYY-MM-DDTHH:MM:SSZ."
  type        = string
  default     = "2026-07-01T00:00:00Z"
}

variable "alert_email" {
  description = "Email address that receives FinOps and security alerts."
  type        = string
  default     = "alerts@example.com"
}

variable "apim_publisher_email" {
  description = "Email shown on the APIM developer portal as the publisher."
  type        = string
  default     = "alerts@example.com"
}

variable "apim_publisher_name" {
  description = "Publisher name shown on the APIM developer portal."
  type        = string
  default     = "AI Hub Reference Implementation"
}

variable "chat_model_capacity" {
  description = "Chat model deployment capacity in thousands of tokens per minute."
  type        = number
  default     = 10
}

variable "chat_model_name" {
  description = "Chat model name. Pick a model available in your chosen region."
  type        = string
  default     = "gpt-4o-mini"
}

variable "chat_model_version" {
  description = "Chat model version. Blank takes Azure default."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tag set applied to every resource."
  type        = map(string)
  default = {
    workload    = "aihub"
    environment = "poc"
    costCenter  = "your-cost-center"
    managedBy   = "terraform"
    owner       = "platform-team"
    application = "ai-hub-reference"
  }
}
