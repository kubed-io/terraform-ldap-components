mock_provider "ldap" {}
mock_provider "random" {}

variables {
  base_dn = "ou=services,dc=example"
  posix = {
    uidNumber = "1050"
    gidNumber = "2001"
  }
}

run "name_defaults_to_workspace" {
  command = plan
  # no name set → falls back to terraform.workspace ("default" under tofu test)

  assert {
    condition     = ldap_entry.this.dn == "uid=default,ou=services,dc=example"
    error_message = "name should fall back to the workspace name when unset"
  }
}

run "rejects_short_password" {
  command = plan
  variables {
    name = "myapp"
    password_policy = {
      length = 8
    }
  }
  expect_failures = [var.password_policy]
}
