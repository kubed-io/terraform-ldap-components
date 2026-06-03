variable "name" {
  description = "The client name. Becomes the root cn; RDN is cn=<name>. Defaults to the workspace name."
  type        = string
  default     = null
  nullable    = true
}

variable "base_dn" {
  description = "Parent DN the client root is created under (e.g. ou=clients,dc=example). The RDN cn=<name> is prepended; role children go under the root as cn=<role>,cn=<name>,<base_dn>."
  type        = string
}

variable "owner" {
  description = <<EOF
DN of the client owner — conventionally the service account that runs the app. REQUIRED:
it links the client back to its app and is seeded as the initial `member` on the root AND
every role child so each groupOfNames satisfies the >=1-member rule. Membership is then
ignored (see below) and filled by an external tool.
EOF
  type        = string
}

variable "roles" {
  description = <<EOF
Client roles for this client. Each becomes a child groupOfNames at cn=<name>,cn=<client>,<base_dn>.
The client owns the role *structure*; membership of each child is external (ignored), just
like the root.
EOF
  type = list(object({
    name        = string
    description = optional(string, null)
  }))
  default = []
}

variable "url" {
  description = <<EOF
App URL stored as labeledURI on the client root. posixGroup/groupOfNames have no such
attribute, so the module adds the labeledURIObject auxiliary class when this is set.
Omitted when null.
EOF
  type        = string
  default     = null
  nullable    = true
}

# ---- common optional descriptive keys (groupOfNames MAY; see top-level README) ----

variable "description" {
  description = "Human blurb (description) on the client root. Omitted when null."
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
