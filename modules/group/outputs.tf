output "dn" {
  description = "The full DN of the group (cn=<name>,<base_dn>)."
  value       = ldap_entry.this.dn
}

output "cn" {
  description = "The group's common name."
  value       = local.name
}

output "gid_number" {
  description = "The POSIX gidNumber."
  value       = var.gid_number
}

output "members" {
  description = "The resolved memberUid set written to the group."
  value       = var.members
}
