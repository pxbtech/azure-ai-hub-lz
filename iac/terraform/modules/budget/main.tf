resource "azurerm_consumption_budget_subscription" "budget" {
  name            = var.budget_name
  subscription_id = var.subscription_id
  amount          = var.amount
  time_grain      = "Monthly"

  time_period {
    start_date = var.start_date
  }

  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled         = true
    threshold       = 100
    operator        = "GreaterThanOrEqualTo"
    threshold_type  = "Actual"
    contact_emails  = [var.alert_email]
    contact_groups  = [var.action_group_id]
  }
}
