output "dn" {
  description = "The full DN of the service account (uid=<name>,<base_dn>)."
  value       = ldap_entry.this.dn
}

output "username" {
  description = "The uid (name) of the service account. Goes in the connection Secret as `username`."
  value       = local.name
}

output "password" {
  description = "The generated userPassword (the Secret's `password`). Null when a `password` was supplied — the caller already has it."
  value       = local.generate_password ? random_password.this[0].result : null
  sensitive   = true
}

output "posix" {
  description = "The resolved unix-plane attributes (mirrors the `posix` input, with homeDirectory and loginShell defaulted)."
  value = {
    uidNumber     = var.posix.uidNumber
    gidNumber     = var.posix.gidNumber
    homeDirectory = local.home_directory
    loginShell    = var.posix.loginShell
  }
}

output "mail" {
  description = "The email address. Empty string when not set."
  value       = var.mail != null ? var.mail : ""
}
