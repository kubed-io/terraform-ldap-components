# Role

Creates a single **realm-wide capability** — a `groupOfNames` entry on the **IAM
plane**. A role maps to a Keycloak **realm role** (`realm_access.roles`); each OIDC
app is configured individually to honor it (opt-in, not automatic). The RDN is
`cn=<name>`, placed under whatever `base_dn` you hand it (conventionally
`ou=roles,dc=<base>`).

See the [top-level README](../../README.md) for the two-planes model and the WHO/WHAT
(group vs role) distinction. Common roles: `admins`, `editor`, `viewer` (+ optional
`superadmin`, `guest`). There is no `anonymous` role — anonymous means *no token*.

## Membership is authoritative

Unlike a [`Team`](../team), a Role is the **single writer** of its `member` attribute:
the module writes the full `members` set and removes anything not present. Because
`groupOfNames` requires at least one `member` (RFC 4519), when `members` is empty the
module seeds the required `owner` as the sole sentinel member; the sentinel is dropped
as soon as a real member exists. `member` is **not** ignored.

## Variables

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `name` | string | no | workspace name | cn; RDN is `cn=<name>` |
| `base_dn` | string | yes | — | parent DN the entry is created under |
| `members` | set(string) | no | `[]` | member DNs (any subject); authoritative, de-duplicated, sorted on write |
| `owner` | string (DN) | yes | — | administrator DN; sentinel member when `members` is empty |
| `description` | string | no | `null` | human blurb (`description`) |
| `see_also` | string (DN) | no | `null` | cross-reference (`seeAlso`) |
| `category` | string | no | `null` | classification tag (`businessCategory`) |
| `org` | string | no | `null` | organization-name tag (`o`) |
| `org_unit` | string | no | `null` | org-unit tag (`ou`) **on the entry** — a label, not the DN's structural `ou` |

### `members`

Any subject DN — a person (`uid=...,ou=users,...`) or a service account
(`uid=...,ou=services,...`); LDAP doesn't distinguish. A **set**, so reordering or
duplicates never produce a diff.

## Outputs

| Name | Description |
| --- | --- |
| `dn` | full DN (`cn=<name>,<base_dn>`) |
| `cn` | the role's common name |
| `owner` | the owner DN (also the sentinel member) |
| `members` | the resolved authoritative member set (the owner sentinel when none were given) |

## Example

```hcl
module "role" {
  source = "git::https://github.com/kubed-io/terraform-ldap-components.git//modules/role?ref=main"

  name    = "admins"
  base_dn = "ou=roles,dc=example"
  owner   = "uid=alice,ou=users,dc=example"
  members = [
    "uid=alice,ou=users,dc=example",
    "uid=bob,ou=users,dc=example",
  ]
  description = "Full admin across apps that honor it."
}
```

A runnable version (using a local relative `source`) lives in
[`examples/role`](../../examples/role).

## References

- [OpenTofu LDAP Provider — `ldap_entry`](https://search.opentofu.org/provider/l-with/ldap/latest/docs/resources/entry)
- [RFC 4519 — `groupOfNames` schema](https://www.rfc-editor.org/rfc/rfc4519)
- [OpenLDAP Overlays — `memberOf`](https://www.openldap.org/doc/admin24/overlays.html)
