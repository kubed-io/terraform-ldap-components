mock_provider "ldap" {}
mock_provider "random" {}

variables {
  name    = "myapp"
  base_dn = "ou=services,dc=example"
  posix = {
    uidNumber = "1050"
    gidNumber = "2001"
  }
}

run "builds_dn_from_name_and_base" {
  command = plan

  assert {
    condition     = ldap_entry.this.dn == "uid=myapp,ou=services,dc=example"
    error_message = "DN should be uid=<name>,<base_dn>"
  }
  # the connection-secret contract: consumers read `username`
  assert {
    condition     = output.username == "myapp"
    error_message = "username output should be the name (connection-secret key)"
  }
}

run "writes_core_posix_attrs" {
  command = plan

  assert {
    condition     = jsondecode(ldap_entry.this.data_json).uidNumber == ["1050"]
    error_message = "uidNumber should come from posix.uidNumber"
  }
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).gidNumber == ["2001"]
    error_message = "gidNumber should come from posix.gidNumber"
  }
  assert {
    condition     = contains(jsondecode(ldap_entry.this.data_json).objectClass, "posixAccount")
    error_message = "posixAccount objectClass must be present"
  }
}

run "defaults_home_shell_and_sn" {
  command = plan

  assert {
    condition     = jsondecode(ldap_entry.this.data_json).homeDirectory == ["/home/myapp"]
    error_message = "homeDirectory should default to /home/<name>"
  }
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).loginShell == ["/usr/sbin/nologin"]
    error_message = "loginShell should default to nologin for service accounts"
  }
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).sn == ["myapp"]
    error_message = "sn should default to the name"
  }
}

run "omits_unset_optional_attrs" {
  command = plan

  assert {
    condition     = !can(jsondecode(ldap_entry.this.data_json).mail)
    error_message = "mail must not be written when unset"
  }
  assert {
    condition     = !can(jsondecode(ldap_entry.this.data_json).description)
    error_message = "description must not be written when unset"
  }
}

run "generates_password_by_default" {
  command = plan

  assert {
    condition     = length(random_password.this) == 1
    error_message = "a password should be generated when none is supplied"
  }
}

run "uses_supplied_password" {
  command = plan
  variables {
    password = "byo-secret-password"
  }

  assert {
    condition     = length(random_password.this) == 0
    error_message = "no password should be generated when one is supplied"
  }
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).userPassword == ["byo-secret-password"]
    error_message = "the supplied password should be written verbatim"
  }
  assert {
    condition     = output.password == null
    error_message = "the password output must be null when one was supplied"
  }
}

run "writes_optional_attrs_when_set" {
  command = plan
  variables {
    mail        = "myapp@example.com"
    description = "the myapp service account"
    sn          = "Application"
    posix = {
      uidNumber     = "1050"
      gidNumber     = "2001"
      homeDirectory = "/srv/myapp"
      loginShell    = "/bin/bash"
    }
  }

  assert {
    condition     = jsondecode(ldap_entry.this.data_json).mail == ["myapp@example.com"]
    error_message = "mail should be written when set"
  }
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).description == ["the myapp service account"]
    error_message = "description should be written when set"
  }
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).sn == ["Application"]
    error_message = "explicit sn should override the name default"
  }
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).homeDirectory == ["/srv/myapp"]
    error_message = "explicit homeDirectory should override the default"
  }
  assert {
    condition     = jsondecode(ldap_entry.this.data_json).loginShell == ["/bin/bash"]
    error_message = "explicit loginShell should override the default"
  }
}
