output "dn" {
  description = "The full DN of the team (cn=<name>,<base_dn>)."
  value       = ldap_entry.this.dn
}

output "cn" {
  description = "The team's common name."
  value       = local.name
}

output "owner" {
  description = "The owner DN (also the seed member)."
  value       = var.owner
}
