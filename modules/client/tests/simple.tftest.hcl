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
  # the root is a pure container, NOT a membership group → organizationalRole
  assert {
    condition     = jsondecode(ldap_entry.root.data_json).objectClass == ["organizationalRole"]
    error_message = "a bare client root is only organizationalRole (no aux classes)"
  }
}

run "root_is_container_not_group" {
  command = plan

  # the SA back-link is roleOccupant (organizationalRole's native attr), not owner
  assert {
    condition     = jsondecode(ldap_entry.root.data_json).roleOccupant == ["uid=nextcloud,ou=services,dc=example"]
    error_message = "the owning SA should be written as roleOccupant on the root"
  }
  # the root carries NO member ACL — membership lives on the role children
  assert {
    condition     = !can(jsondecode(ldap_entry.root.data_json).member)
    error_message = "the client root must NOT carry a member list (access = any client role)"
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

run "category_org_add_extensible_object" {
  command = plan
  variables {
    category = "internal"
    org      = "example-org"
  }

  # organizationalRole has no businessCategory/o → needs extensibleObject
  assert {
    condition     = contains(jsondecode(ldap_entry.root.data_json).objectClass, "extensibleObject")
    error_message = "category/org must pull in the extensibleObject auxiliary class on the root"
  }
  assert {
    condition     = jsondecode(ldap_entry.root.data_json).businessCategory == ["internal"]
    error_message = "category should map to businessCategory"
  }
  assert {
    condition     = jsondecode(ldap_entry.root.data_json).o == ["example-org"]
    error_message = "org should map to o"
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
