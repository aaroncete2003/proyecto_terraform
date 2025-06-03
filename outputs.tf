output "resource_group_name" {
description = "Nombre del grupo de recursos"
value = azurerm_resource_group.main.name
}
output "service_bus_namespace" {
description = "Nombre del Service Bus Namespace"
value = azurerm_servicebus_namespace.main.name
}
output "service_bus_connection" {
description = "Cadena de conexión del Service Bus"
value = azurerm_servicebus_namespace.main.default_primary_connection_string
sensitive = true
}
output "function_app_name" {
description = "Nombre de la Function App"
value = azurerm_linux_function_app.processor.name
}
output "storage_account_name" {
description = "Nombre de la cuenta de almacenamiento"
value = azurerm_storage_account.functions.name
}
