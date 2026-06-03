# Group

Creates a single **POSIX group** — a `posixGroup` entry on the **unix plane** (NAS
shares, sshd, folder permissions). The RDN is `cn=<name>`, placed under whatever
`base_dn` you hand it (conventionally `ou=groups,dc=<base>`).

`posixGroup` is a small RFC 2307 class: MUST `cn` + `gidNumber`; MAY `memberUid`,
`userPassword`, `description`. It does **not** feed the `memberOf` overlay or
Keycloak — for the IAM plane use a [`Team`](../team), [`Role`](../role), or
[`Client`](../client). See the [top-level README](../../README.md) for the two-planes model.

This module is **CRD-authoritative** for membership: it writes the full `memberUid`
set and removes anything not present (single writer — no external writer, no selector).

## Variables

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `name` | string | no | workspace name | cn; RDN is `cn=<name>` |
| `base_dn` | string | yes | — | parent DN the entry is created under |
| `gid_number` | string | yes | — | POSIX gidNumber; globally unique |
| `members` | set(string) | no | `[]` | bare uids (`memberUid`); unordered, de-duplicated, sorted on write |
| `description` | string | no | `null` | human blurb (`description`) |
| `mail` | string | no | `null` | informational group email; see below |

### `members`

A **set** of bare uids — users and/or service accounts. Set semantics match LDAP's
multi-valued, unordered `memberUid`, so reordering or duplicates never produce a
diff. There is **no referential integrity** on `memberUid` (it's a uid string, not a
DN); it relies on the global uid-uniqueness invariant and is resolved by the consumer
via a flat subtree search — so the consumer's user search base must cover
`ou=services` for a service account member to resolve.

### `mail`

`posixGroup` has no `mail` attribute, so setting `mail` makes the module add the
`extensibleObject` auxiliary class. **Informational only** — a typical mail server
treats a group `mail` as a single alias, not a member-expanding distribution list.

## Outputs

| Name | Description |
| --- | --- |
| `dn` | full DN (`cn=<name>,<base_dn>`) |
| `cn` | the group's common name |
| `gid_number` | the POSIX gidNumber |
| `members` | the resolved `memberUid` set |

## Example

```hcl
module "group" {
  source = "git::https://github.com/kubed-io/terraform-ldap-components.git//modules/group?ref=main"

  name       = "media"
  base_dn    = "ou=groups,dc=example"
  gid_number = "2020"
  members    = ["alice", "myapp"]
}
```

A runnable version (using a local relative `source`) lives in
[`examples/group`](../../examples/group).

## References

- [OpenTofu LDAP Provider — `ldap_entry`](https://search.opentofu.org/provider/l-with/ldap/latest/docs/resources/entry)
- [RFC 2307 — `posixGroup` (NIS) schema](https://www.rfc-editor.org/rfc/rfc2307)
