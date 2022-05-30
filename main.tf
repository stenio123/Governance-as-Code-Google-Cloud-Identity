################ Org Units
# Root org
# Execute terraform import googleworkspace_org_unit.org "id:01ab2c3d4efg56h" for existing org
resource "googleworkspace_org_unit" "parent" {
  name                 = "sales"
  description          = "sales"
  parent_org_unit_path = "/"
}

# Children org
locals {
  # We've included this inline to create a complete example, but in practice
  # this is more likely to be loaded from a file using the "file" function.
  csv_data_orgs = <<-CSV
    local_id, name,description
    1, Governance, Governance
    2, Operations, Operations
    3, Development, Development
  CSV

  orgs = csvdecode(local.csv_data_orgs)
}

resource "googleworkspace_org_unit" "child" {
  for_each = { for org in local.orgs : org.local_id => org }

  name                 = each.value.name
  description          = each.value.description
  parent_org_unit_path = googleworkspace_org_unit.parent.org_unit_path
}

################# Users
locals {
  # We've included this inline to create a complete example, but in practice
  # this is more likely to be loaded from a file using the "file" function.
  csv_data_users = <<-CSV
    local_id, primary_email,family_name, given_name, org_unit, group
    mega@steniof.altostrat.com, mega@steniof.altostrat.com, Governance, Mega, Governance, Governance
    super@steniof.altostrat.com, super@steniof.altostrat.com, Operations, Super, Operations,Operations
    cool@steniof.altostrat.com, cool@steniof.altostrat.com, Development, Cool, Development, Development
  CSV

  users = csvdecode(local.csv_data_users)
}

resource "googleworkspace_user" "user_list" {
  for_each      = { for user in local.users : user.local_id => user }
  primary_email = each.value.primary_email
  password      = "ThisIsVeryUnsecure123#"
  #change_password_at_next_login = true
  hash_function = "MD5"

  name {
    family_name = each.value.family_name
    given_name  = each.value.given_name
  }
  # TODO check if parent path ends with '/'
  org_unit_path = googleworkspace_org_unit.parent.org_unit_path + each.value.org_unit

}

################# Groups
# For simplicity I am assuming that Groups have same name as Orgs
resource "googleworkspace_group" "groups" {
  for_each = { for org in local.orgs : org.local_id => org }
  email    = each.value.name + "@steniof.altostrat.com"
}

resource "googleworkspace_group_settings" "group-settings" {
  for_each = { for org in local.orgs : org.local_id => org }
  email    = each.value.name + "@steniof.altostrat.com"

  allow_external_members = false

  who_can_join            = "INVITED_CAN_JOIN"
  who_can_view_membership = "ALL_MANAGERS_CAN_VIEW"
  who_can_post_message    = "ALL_MEMBERS_CAN_POST"
}

resource "googleworkspace_group_member" "members" {
  for_each = { for user in local.users : user.local_id => user }
  #TODO figure out how to reference group id
  #group_id= googleworkspace_group.sales.id
  group_id = each.value.group
  email    = each.value.primary_email
}
