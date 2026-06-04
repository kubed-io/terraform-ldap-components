# Client

Creates a **per-app login surface** on the **IAM plane** — an `organizationalRole`
**root container** plus one `groupOfNames` **child per declared client role**. A client
is the **1:1 counterpart of one OIDC client** (a Keycloak `OpenidClient`): each child
role maps to a Keycloak **client role**, and **access to the app = being a member of any
of the client's role children** (there is no separate root ACL). The RDN is `cn=<name>`
under your `base_dn` (conventionally `ou=clients,dc=<base>`); role children nest as
`cn=<role>,cn=<name>,<base_dn>`.

One app service account can own **many** clients — e.g. a Drupal multisite where one
`uid=drupal,ou=services` runs every site but each site is its own client
(`cn=drupal-default,ou=clients`, `cn=acme-site,ou=clients`, …) with its own role children.
See the [top-level README](../../README.md) for the two-planes model.

## The root is a container, not a membership group

The root is an **`organizationalRole`** (MUST `cn` only — no required `member`): a pure
container that nests the role children and carries the metadata. It records the owning
service account as **`roleOccupant`** (organizationalRole's native "who occupies this
role" DN attribute). Auxiliary classes are added only as needed: `labeledURIObject` when
`url` is set, `extensibleObject` when `category`/`org` is set.

**Membership lives only on the role children.** Each role child is a `groupOfNames`; the
module seeds `owner` as its initial member (to satisfy `groupOfNames`' ≥1-member MUST) and
then **preserves externally-added members**: on every reconcile it reads the child's
current members (via the `ldap_entries` data source, empty before it exists) and writes
`owner ∪ existing`, so an external tool (onboarding workflow / the app) can add members
without Terraform wiping them. No `ignore_attributes` needed.

A client holds **no credentials** — no password, no bind secret. The `client_secret`
belongs to the Keycloak `OpenidClient` this corresponds to, not here.

> **`Client` (this kind) vs `OpenidClient` (keycloak):** this LDAP object is the
> *access list (role children) + structure* that feeds the client; the keycloak
> `OpenidClient` is the actual client *registration* (redirect URIs, secret, protocol
> mappers). Different plane, different API group — they share a name because they are 1:1.

## Variables

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `name` | string | no | workspace name | root cn; RDN is `cn=<name>` |
| `base_dn` | string | yes | — | parent DN the client root is created under |
| `owner` | string (DN) | yes | — | owning service account; written as `roleOccupant` on the root + seed `member` on every role child |
| `roles` | list(object) | no | `[]` | client roles; each → child `cn=<role>,cn=<name>,<base_dn>` |
| `url` | string | no | `null` | app URL → `labeledURI` (adds `labeledURIObject`) |
| `description` | string | no | `null` | human blurb on the root (`description`) |
| `see_also` | string (DN) | no | `null` | cross-reference (`seeAlso`) |
| `category` | string | no | `null` | classification tag (`businessCategory`) |
| `org` | string | no | `null` | organization-name tag (`o`) |
| `org_unit` | string | no | `null` | org-unit tag (`ou`) **on the entry** — a label, not the DN's structural `ou` |

### `roles`

Each entry is `{ name, description? }` and materializes a client-role child
`groupOfNames`. The client owns the role *structure* — adding a role is a one-line
change. Each child's membership is the grant *and* the access list: a principal is in the
app by being a `member` of any child (external members are preserved, see above).

## Outputs

| Name | Description |
| --- | --- |
| `dn` | full DN of the client root (`cn=<name>,<base_dn>`) |
| `cn` | the client's common name |
| `owner` | the owning service account DN (`roleOccupant` on the root; seed member of each child) |
| `role_dns` | map of role name → full DN of its client-role child |

## Example

```hcl
module "client" {
  source = "git::https://github.com/kubed-io/terraform-ldap-components.git//modules/client?ref=main"

  name    = "nextcloud"
  base_dn = "ou=clients,dc=example"
  owner   = "uid=nextcloud,ou=services,dc=example"
  url     = "https://nextcloud.example.com"
  roles = [
    { name = "admin", description = "Nextcloud administrators" },
    { name = "media-manager" },
  ]
}
```

A runnable version (using a local relative `source`) lives in
[`examples/client`](../../examples/client).

## References

- [OpenTofu LDAP Provider — `ldap_entry`](https://search.opentofu.org/provider/l-with/ldap/latest/docs/resources/entry)
- [RFC 4519 — `groupOfNames` schema](https://www.rfc-editor.org/rfc/rfc4519)
- [OpenLDAP Overlays — `memberOf`](https://www.openldap.org/doc/admin24/overlays.html)
