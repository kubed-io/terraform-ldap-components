variable "name" {
  description = "The service account name. Becomes the uid and the cn; RDN is uid=<name>. Defaults to the workspace name. Must be globally unique across ou=users + ou=services."
  type        = string
  default     = null
  nullable    = true
}

variable "base_dn" {
  description = "Parent DN the entry is created under (placement is a parameter, e.g. ou=services,dc=example). The RDN uid=<name> is prepended by the module."
  type        = string
}

variable "posix" {
  description = <<EOF
The unix-plane attributes (the /etc/passwd fields). uidNumber and gidNumber are
required; uidNumber is globally unique across users + services, and gidNumber is
the PRIMARY group only (supplementary membership is written by a Group, never here).
homeDirectory defaults to /home/<name>; loginShell defaults to /usr/sbin/nologin
(service accounts get no shell unless asked).
EOF
  type = object({
    uidNumber     = string
    gidNumber     = string
    homeDirectory = optional(string, null)
    loginShell    = optional(string, "/usr/sbin/nologin")
  })
}

variable "sn" {
  description = "Surname (sn). Required by inetOrgPerson; defaults to the name when unset."
  type        = string
  default     = null
  nullable    = true
}

variable "password" {
  description = <<EOF
Bring-your-own userPassword. When set, the module uses it verbatim and does NOT
generate one (password_policy is ignored), and it is NOT re-exposed as an output
(the caller already has it). Leave null to have the module generate one per
password_policy.
EOF
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
}

variable "password_policy" {
  description = <<EOF
Generation policy for the account's userPassword, passed straight to the random_password
resource. Ignored when `password` is supplied. Defaults are production-safe: 16 chars
with at least one of every character class, and a shell-safe special set (no quotes,
backslash, backtick, or $ that break in env files). Tune per account if needed.
EOF
  type = object({
    length          = optional(number, 16)
    special         = optional(bool, true)
    numeric         = optional(bool, true)
    upper           = optional(bool, true)
    lower           = optional(bool, true)
    minSpecial      = optional(number, 1)
    minNumeric      = optional(number, 1)
    minUpper        = optional(number, 1)
    minLower        = optional(number, 1)
    overrideSpecial = optional(string, "!#%&*()-_=+[]{}<>:?")
  })
  default = {}

  validation {
    condition     = var.password_policy.length >= 16
    error_message = "password_policy.length must be at least 16 for production-safe credentials."
  }
}

# ---- common optional descriptive keys (see README "Common fields") ----

variable "description" {
  description = "Human blurb (description). Omitted when null."
  type        = string
  default     = null
  nullable    = true
}

variable "mail" {
  description = "Email address (mail). Omitted when null."
  type        = string
  default     = null
  nullable    = true
}
