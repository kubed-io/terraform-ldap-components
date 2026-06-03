variable "name" {
  description = "The role name. Becomes the cn; RDN is cn=<name>. Defaults to the workspace name."
  type        = string
  default     = null
  nullable    = true
}

variable "base_dn" {
  description = "Parent DN the entry is created under (e.g. ou=roles,dc=example). The RDN cn=<name> is prepended by the module."
  type        = string
}

variable "members" {
  description = <<EOF
Member DNs — any subject (LDAP doesn't care whether it's a person or a service account).
Authoritative: the module writes the FULL set and removes anything not present (single
writer). A set: unordered and de-duplicated, so reordering never shows as a diff.
EOF
  type        = set(string)
  default     = []
}

variable "owner" {
  description = <<EOF
DN of the role's administrator. REQUIRED as the sentinel: groupOfNames demands at least
one `member`, so when `members` is empty the module seeds `owner` as the sole member to
keep the entry valid. Once a real member exists, the seed is dropped.
EOF
  type        = string
}

# ---- common optional descriptive keys (groupOfNames MAY; see top-level README) ----

variable "description" {
  description = "Human blurb (description). Omitted when null."
  type        = string
  default     = null
  nullable    = true
}

variable "see_also" {
  description = "DN cross-reference to a related entry (seeAlso). Omitted when null."
  type        = string
  default     = null
  nullable    = true
}

variable "category" {
  description = "Free-text classification tag (businessCategory). Omitted when null."
  type        = string
  default     = null
  nullable    = true
}

variable "org" {
  description = "Organization-name tag (o). Omitted when null."
  type        = string
  default     = null
  nullable    = true
}

variable "org_unit" {
  description = "Organizational-unit tag (ou) ON the entry — a label, NOT the DN's structural ou. Omitted when null."
  type        = string
  default     = null
  nullable    = true
}
