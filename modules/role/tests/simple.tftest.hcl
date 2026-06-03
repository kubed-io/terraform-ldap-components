mock_provider "ldap" {}

variables {
  name    = "admins"
  base_dn = "ou=roles,dc=example"
  owner   = "uid=alice,ou=users,dc=example"
}

run "builds_dn_and_core_attrs" {
  command = plan

  assert {
    condition     = ldap_entry.this.dn == "cn=admins,ou=roles,dc=example"
    error_message = "DN should be cn=<name>,<base_dn>"
  }
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).objectClass == ["groupOfNames"]
    error_message = "a role is a groupOfNames"
  }
}

run "seeds_owner_when_no_members" {
  command = plan

  assert {
    condition     = jsondecode(ldap_entry.this.data_json).member == ["uid=alice,ou=users,dc=example"]
    error_message = "owner should be the sentinel member when members is empty"
  }
}

run "writes_authoritative_members" {
  command = plan
  variables {
    members = [
      "uid=bob,ou=users,dc=example",
      "uid=carol,ou=users,dc=example",
      "uid=myapp,ou=services,dc=example",
    ]
  }

  assert {
    condition = jsondecode(ldap_entry.this.data_json).member == [
      "uid=bob,ou=users,dc=example",
      "uid=carol,ou=users,dc=example",
      "uid=myapp,ou=services,dc=example",
    ]
    error_message = "member should be the sorted set of provided members"
  }
  # owner sentinel is dropped once real members exist
  assert {
    condition     = !contains(jsondecode(ldap_entry.this.data_json).member, "uid=alice,ou=users,dc=example")
    error_message = "owner sentinel should NOT appear once real members are set"
  }
}

run "dedupes_members" {
  command = plan
  variables {
    members = [
      "uid=bob,ou=users,dc=example",
      "uid=bob,ou=users,dc=example",
    ]
  }

  assert {
    condition     = length(jsondecode(ldap_entry.this.data_json).member) == 1
    error_message = "duplicate members should collapse (set semantics)"
  }
}

run "no_ignore_attributes" {
  command = plan

  assert {
    condition     = ldap_entry.this.ignore_attributes == null
    error_message = "role is authoritative — member must NOT be ignored (ignore_attributes must be null)"
  }
}

run "writes_optional_tags" {
  command = plan
  variables {
    description = "Full admin across apps that honor it"
  }

  assert {
    condition     = jsondecode(ldap_entry.this.data_json).description == ["Full admin across apps that honor it"]
    error_message = "description should be written when set"
  }
}
