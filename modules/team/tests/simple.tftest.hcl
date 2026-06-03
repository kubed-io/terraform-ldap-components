mock_provider "ldap" {
  # team not yet present → the live-members lookup returns an empty list
  mock_data "ldap_entries" {
    defaults = {
      entries = []
    }
  }
}

variables {
  name    = "staff"
  base_dn = "ou=teams,dc=example"
  owner   = "uid=alice,ou=users,dc=example"
}

run "builds_dn_and_core_attrs" {
  command = plan

  assert {
    condition     = ldap_entry.this.dn == "cn=staff,ou=teams,dc=example"
    error_message = "DN should be cn=<name>,<base_dn>"
  }
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).objectClass == ["groupOfNames"]
    error_message = "a team is a groupOfNames"
  }
}

run "seeds_owner_as_member_when_empty" {
  command = plan

  # with no existing entry (mock returns empty), members = [owner]
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).member == ["uid=alice,ou=users,dc=example"]
    error_message = "owner should be the sole seed member when the team has none yet"
  }
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).owner == ["uid=alice,ou=users,dc=example"]
    error_message = "owner attribute should be written"
  }
}

run "does_not_ignore_member" {
  command = plan

  # membership is preserved via the data-source merge, NOT ignore_attributes
  assert {
    condition     = ldap_entry.this.ignore_attributes == null
    error_message = "member must NOT be ignored (preserved via the ldap_entries merge instead)"
  }
}

run "writes_optional_tags" {
  command = plan
  variables {
    description = "Internal staff"
    see_also    = "cn=nextcloud,ou=clients,dc=example"
    category    = "internal"
    org         = "example-org"
    org_unit    = "engineering"
  }

  assert {
    condition     = jsondecode(ldap_entry.this.data_json).description == ["Internal staff"]
    error_message = "description should be written when set"
  }
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).seeAlso == ["cn=nextcloud,ou=clients,dc=example"]
    error_message = "see_also should map to seeAlso"
  }
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).businessCategory == ["internal"]
    error_message = "category should map to businessCategory"
  }
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).o == ["example-org"]
    error_message = "org should map to o"
  }
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).ou == ["engineering"]
    error_message = "org_unit should map to ou"
  }
}

run "omits_unset_tags" {
  command = plan

  assert {
    condition     = !can(jsondecode(ldap_entry.this.data_json).seeAlso)
    error_message = "seeAlso must be omitted when unset"
  }
  assert {
    condition     = !can(jsondecode(ldap_entry.this.data_json).businessCategory)
    error_message = "businessCategory must be omitted when unset"
  }
}
