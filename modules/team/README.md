# Team

Creates a single **cohort of humans** — a `groupOfNames` entry on the **IAM plane**.
A team maps to a Keycloak **group**; use it for organizational grouping (WHO you
are), **not** access gating (that's a [`Client`](../client)). The RDN is `cn=<name>`,
placed under whatever `base_dn` you hand it (conventionally `ou=teams,dc=<base>`).

See the [top-level README](../../README.md) for the two-planes model and the
membership rules.

## Membership is externally managed

`groupOfNames` requires at least one `member` (RFC 4519), so the module seeds the
required `owner` as the initial `member` to make the entry valid on create, then sets
`ignore_attributes = ["member"]`. From then on **terraform never touches `member`** —
an external tool (e.g. an onboarding workflow) is the sole writer of who's on the team.
There is therefore **no `members` input and no selector** on this kind.

## Variables

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `name` | string | no | workspace name | cn; RDN is `cn=<name>` |
| `base_dn` | string | yes | — | parent DN the entry is created under |
| `owner` | string (DN) | yes | — | administrator DN; also the seed `member` |
| `description` | string | no | `null` | human blurb (`description`) |
| `see_also` | string (DN) | no | `null` | cross-reference (`seeAlso`) to a related entry |
| `category` | string | no | `null` | classification tag (`businessCategory`) |
| `org` | string | no | `null` | organization-name tag (`o`) |
| `org_unit` | string | no | `null` | org-unit tag (`ou`) **on the entry** — a label, not the DN's structural `ou` |

## Outputs

| Name | Description |
| --- | --- |
| `dn` | full DN (`cn=<name>,<base_dn>`) |
| `cn` | the team's common name |
| `owner` | the owner DN (also the seed member) |

## Example

```hcl
module "team" {
  source = "git::https://github.com/kubed-io/terraform-ldap-components.git//modules/team?ref=main"

  name        = "staff"
  base_dn     = "ou=teams,dc=example"
  owner       = "uid=alice,ou=users,dc=example"
  description = "Internal staff"
}
```

A runnable version (using a local relative `source`) lives in
[`examples/team`](../../examples/team).

## References

- [OpenTofu LDAP Provider — `ldap_entry`](https://search.opentofu.org/provider/l-with/ldap/latest/docs/resources/entry)
- [RFC 4519 — `groupOfNames` schema](https://www.rfc-editor.org/rfc/rfc4519)
- [OpenLDAP Overlays — `memberOf`](https://www.openldap.org/doc/admin24/overlays.html)
