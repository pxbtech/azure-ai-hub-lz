locals {
  rg_name             = "${var.env_code}-${var.org_code}-rg-${var.workload}"
  law_name            = "${var.env_code}-${var.workload}-law-${var.instance}"
  appi_name           = "${var.env_code}-${var.workload}-appi-${var.instance}"
  vnet_name           = "${var.env_code}-${var.workload}-vnet-${var.instance}"
  kv_name             = "${var.env_code}-${var.workload}-kv-${var.instance}"
  storage_name        = "${var.env_code}${var.workload}st${var.instance}"
  content_safety_name = "${var.env_code}-${var.workload}-cs-${var.instance}"
  language_name       = "${var.env_code}-${var.workload}-lang-${var.instance}"
  foundry_name        = "${var.env_code}-${var.workload}-aif-${var.instance}"
  apim_name           = "${var.env_code}-${var.workload}-apim-${var.instance}"
  action_group_name   = "${var.env_code}-${var.workload}-ag-${var.instance}"
  budget_name         = "${var.env_code}-${var.workload}-budget-${var.instance}"
}
