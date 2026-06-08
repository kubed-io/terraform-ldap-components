variable "name" {
  description = "The group name. Becomes the cn; RDN is cn=<name>. Defaults to the workspace name."
  type        = string
  default     = null
  nullable    = true
}

variable "base_dn" {
  description = "Parent DN the entry is created under (e.g. ou=groups,dc=example). The RDN cn=<name> is prepended by the module."
  type        = string
}

variable "gid_number" {
  description = "POSIX gidNumber. Required and globally unique."
  type        = string
}

variable "members" {
  description = <<EOF
Bare uids (memberUid) — users and/or service accounts. A set: unordered and de-duplicated,
matching LDAP's multi-valued memberUid, so reordering never shows as a diff. The composition
hands this in already merged from two sources (the CRD's curated `spec.members` and the
serviceAccountSelector-resolved uids on `status.selectedMembers`); the module then UNIONs it
with the live memberUid read back from the server, so ad-hoc grants survive every reconcile.
Not authoritative — the write is the union, never a replace. There is no referential
integrity on memberUid (it is not a DN); it relies on the global uid-uniqueness invariant and
is resolved by the consumer via a flat subtree search.
EOF
  type        = set(string)
  default     = []
}

# ---- common optional descriptive keys (see top-level README) ----
# posixGroup (RFC 2307) is a tiny class: MUST cn + gidNumber; MAY memberUid,
# userPassword, description. `mail` is not in the class and needs an aux objectClass.

variable "description" {
  description = "Human blurb (description). Omitted when null."
  type        = string
  default     = null
  nullable    = true
}

variable "mail" {
  description = <<EOF
Informational group email (the LDAP `mail` attribute). posixGroup has no mail attribute,
so the module adds the extensibleObject auxiliary class when this is set. NOTE: a typical
mail server treats this as a single alias, not a member-expanding distribution list.
Omitted when null.
EOF
  type        = string
  default     = null
  nullable    = true
}
