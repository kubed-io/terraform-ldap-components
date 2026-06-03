variable "name" {
  description = "The team name. Becomes the cn; RDN is cn=<name>. Defaults to the workspace name."
  type        = string
  default     = null
  nullable    = true
}

variable "base_dn" {
  description = "Parent DN the entry is created under (e.g. ou=teams,dc=example). The RDN cn=<name> is prepended by the module."
  type        = string
}

variable "owner" {
  description = <<EOF
DN of the team's administrator. REQUIRED: groupOfNames demands at least one `member`,
and the module seeds `owner` as the initial `member` so the entry is valid on create.
Thereafter `member` is ignored (see below) and an external tool manages real membership.
EOF
  type        = string
}

# ---- common optional descriptive keys (groupOfNames MAY; see top-level README) ----
# These are free-text attributes ON the entry. Note `o`/`ou` here are attribute tags,
# distinct from any structural ou= component in the DN (that is `base_dn` / placement).

variable "description" {
  description = "Human blurb (description). Omitted when null."
  type        = string
  default     = null
  nullable    = true
}

variable "see_also" {
  description = "DN cross-reference to a related entry (seeAlso) — e.g. the client or role this team relates to. Omitted when null."
  type        = string
  default     = null
  nullable    = true
}

variable "category" {
  description = "Free-text classification tag (businessCategory) — environment, classification, etc. Omitted when null."
  type        = string
  default     = null
  nullable    = true
}

variable "org" {
  description = "Organization-name tag (o) — e.g. a tenant label. Omitted when null."
  type        = string
  default     = null
  nullable    = true
}

variable "org_unit" {
  description = "Organizational-unit tag (ou) ON the entry — a free-text label, NOT the DN's structural ou. Omitted when null."
  type        = string
  default     = null
  nullable    = true
}
