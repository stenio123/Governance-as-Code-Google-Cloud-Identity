provider "googleworkspace" {
  credentials             = var.credentials
  customer_id             = var.customer_id
  impersonated_user_email = var.impersonated_user_email
}