terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.81"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.1"
    }
  }
}

provider "azurerm" {
  features {}
  
}

# Generar sufijo único
resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

# Grupo de recursos principal
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Service Bus Namespace
resource "azurerm_servicebus_namespace" "main" {
  name                = "sb-${var.project_name}-${var.environment}-${random_integer.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Cola de mensajes principal
resource "azurerm_servicebus_queue" "messages" {
  name         = "messages"
  namespace_id = azurerm_servicebus_namespace.main.id
  
  # Configuraciones importantes
  max_delivery_count                   = 10
  dead_lettering_on_message_expiration = true
  default_message_ttl                  = "P14D" # 14 días
  
  # Opcional: habilitar particionado si el namespace lo soporta
  # enable_partitioning = true  # Solo disponible en Premium SKU
}

# Storage Account para Azure Functions
resource "azurerm_storage_account" "functions" {
  name                     = "st${var.project_name}${var.environment}${random_integer.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Plan de App Service para Functions
resource "azurerm_service_plan" "functions" {
  name                = "asp-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption Plan (pago por uso)
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Azure Function App
resource "azurerm_linux_function_app" "processor" {
  name                = "func-${var.project_name}-${var.environment}-${random_integer.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key
  service_plan_id           = azurerm_service_plan.functions.id
  
  app_settings = {
    "ServiceBusConnection"          = azurerm_servicebus_namespace.main.default_primary_connection_string
    "FUNCTIONS_WORKER_RUNTIME"      = "dotnet"
    "AzureWebJobsDisableHomepage"   = "true"
  }
  
  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
  }
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
