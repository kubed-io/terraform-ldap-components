mock_provider "ldap" {
  # client/role-children not yet present → live-members lookups return empty lists
  mock_data "ldap_entries" {
    defaults = {
      entries = []
    }
  }
}

variables {
  name    = "nextcloud"
  base_dn = "ou=clients,dc=example"
  owner   = "uid=nextcloud,ou=services,dc=example"
}

run "builds_root_dn_and_class" {
  command = plan

  assert {
    condition     = ldap_entry.root.dn == "cn=nextcloud,ou=clients,dc=example"
    error_message = "root DN should be cn=<name>,<base_dn>"
  }
  assert {
    condition     = jsondecode(ldap_entry.root.data_json).objectClass == ["groupOfNames"]
    error_message = "a bare client root is only groupOfNames (no labeledURIObject)"
  }
}

run "seeds_owner_on_root_when_empty" {
  command = plan

  assert {
    condition     = jsondecode(ldap_entry.root.data_json).member == ["uid=nextcloud,ou=services,dc=example"]
    error_message = "owner should be the sole seed member on the root when empty"
  }
  assert {
    condition     = jsondecode(ldap_entry.root.data_json).owner == ["uid=nextcloud,ou=services,dc=example"]
    error_message = "owner attribute should be written on the root"
  }
  assert {
    condition     = ldap_entry.root.ignore_attributes == null
    error_message = "root member must NOT be ignored (preserved via the ldap_entries merge)"
  }
}

run "no_roles_means_no_children" {
  command = plan

  assert {
    condition     = length(ldap_entry.role) == 0
    error_message = "no role children should be created when roles is empty"
  }
}

run "url_adds_labeled_uri_object" {
  command = plan
  variables {
    url = "https://nextcloud.example.com"
  }

  assert {
    condition     = contains(jsondecode(ldap_entry.root.data_json).objectClass, "labeledURIObject")
    error_message = "setting url must pull in the labeledURIObject auxiliary class"
  }
  assert {
    condition     = jsondecode(ldap_entry.root.data_json).labeledURI == ["https://nextcloud.example.com"]
    error_message = "url should be written as labeledURI"
  }
}

run "creates_role_children" {
  command = plan
  variables {
    roles = [
      { name = "admin", description = "Nextcloud administrators" },
      { name = "media-manager" },
    ]
  }

  assert {
    condition     = length(ldap_entry.role) == 2
    error_message = "should create one child per role"
  }
  assert {
    condition     = ldap_entry.role["admin"].dn == "cn=admin,cn=nextcloud,ou=clients,dc=example"
    error_message = "role child DN should nest under the client root"
  }
  assert {
    condition     = jsondecode(ldap_entry.role["admin"].data_json).description == ["Nextcloud administrators"]
    error_message = "role description should be written when set"
  }
  assert {
    condition     = !can(jsondecode(ldap_entry.role["media-manager"].data_json).description)
    error_message = "role description must be omitted when unset"
  }
  assert {
    condition     = jsondecode(ldap_entry.role["admin"].data_json).member == ["uid=nextcloud,ou=services,dc=example"]
    error_message = "each role child should seed owner as its initial member when empty"
  }
  assert {
    condition     = ldap_entry.role["admin"].ignore_attributes == null
    error_message = "each role child's member must NOT be ignored (preserved via merge)"
  }
}
