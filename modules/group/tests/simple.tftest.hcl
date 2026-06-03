mock_provider "ldap" {}

variables {
  name       = "media"
  base_dn    = "ou=groups,dc=example"
  gid_number = "2020"
}

run "builds_dn_and_core_attrs" {
  command = plan

  assert {
    condition     = ldap_entry.this.dn == "cn=media,ou=groups,dc=example"
    error_message = "DN should be cn=<name>,<base_dn>"
  }
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).gidNumber == ["2020"]
    error_message = "gidNumber should be written"
  }
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).objectClass == ["posixGroup"]
    error_message = "a bare group should be only posixGroup (no extensibleObject)"
  }
}

run "empty_members_omits_memberuid" {
  command = plan

  assert {
    condition     = !can(jsondecode(ldap_entry.this.data_json).memberUid)
    error_message = "memberUid must be omitted when there are no members"
  }
}

run "writes_sorted_members" {
  command = plan
  variables {
    members = ["myapp", "alice", "bob"]
  }

  assert {
    condition     = jsondecode(ldap_entry.this.data_json).memberUid == ["alice", "bob", "myapp"]
    error_message = "memberUid should be the sorted set of members"
  }
}

run "dedupes_members" {
  command = plan
  variables {
    members = ["alice", "alice", "bob"]
  }

  assert {
    condition     = length(jsondecode(ldap_entry.this.data_json).memberUid) == 2
    error_message = "duplicate members should collapse (set semantics)"
  }
}

run "mail_adds_extensible_object" {
  command = plan
  variables {
    mail        = "media@example.com"
    description = "media shared folder"
  }

  assert {
    condition     = contains(jsondecode(ldap_entry.this.data_json).objectClass, "extensibleObject")
    error_message = "setting mail must pull in the extensibleObject auxiliary class"
  }
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).mail == ["media@example.com"]
    error_message = "mail should be written when set"
  }
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).description == ["media shared folder"]
    error_message = "description should be written when set"
  }
}

run "name_defaults_to_workspace" {
  command = plan
  variables {
    name = null
  }

  assert {
    condition     = ldap_entry.this.dn == "cn=default,ou=groups,dc=example"
    error_message = "name should fall back to the workspace name when unset"
  }
}
