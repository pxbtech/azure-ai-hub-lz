resource "azurerm_monitor_action_group" "ag" {
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = "aihubag"

  email_receiver {
    name                    = "platform-email"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }

  tags = var.tags
}
