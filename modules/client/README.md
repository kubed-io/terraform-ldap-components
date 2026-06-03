# Client

Creates a **per-app login surface** — a root `groupOfNames` plus one child
`groupOfNames` per declared client role, on the **IAM plane**. A client is the **1:1
counterpart of one OIDC client** (a Keycloak `OpenidClient`): the root membership is
the *access gate* ("may log in") and each child role maps to a Keycloak **client role**.
The RDN is `cn=<name>` under your `base_dn` (conventionally `ou=clients,dc=<base>`);
role children nest as `cn=<role>,cn=<name>,<base_dn>`.

One app service account can own **many** clients — e.g. a Drupal multisite where one
`uid=drupal,ou=services` runs every site but each site is its own client
(`cn=drupal-default,ou=clients`, `cn=acme-site,ou=clients`, …) with its own access list
and client roles. See the [top-level README](../../README.md) for the two-planes model.

## Membership is external; the client has no secret

The client owns **structure** (the root + role children), not membership. Every
`groupOfNames` needs at least one `member` (RFC 4519), so the module seeds `owner` as
the initial member on the root **and** each role child, then sets
`ignore_attributes = ["member"]` everywhere — an external tool (an onboarding workflow
or the app) is the sole writer of who's actually allowed and who holds each client role.

A client holds **no credentials** — no password, no bind secret. It is pure
`groupOfNames` structure. The `client_secret` belongs to the Keycloak `OpenidClient`
this corresponds to, not here.

> **`Client` (this kind) vs `OpenidClient` (keycloak):** this LDAP object is the
> *access list + role structure* that feeds the client; the keycloak `OpenidClient` is
> the actual client *registration* (redirect URIs, secret, protocol mappers). Different
> plane, different API group — they share a name because they are 1:1.

## Variables

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `name` | string | no | workspace name | root cn; RDN is `cn=<name>` |
| `base_dn` | string | yes | — | parent DN the client root is created under |
| `owner` | string (DN) | yes | — | owning service account; seed `member` on root + every child |
| `roles` | list(object) | no | `[]` | client roles; each → child `cn=<role>,cn=<name>,<base_dn>` |
| `url` | string | no | `null` | app URL → `labeledURI` (adds `labeledURIObject`) |
| `description` | string | no | `null` | human blurb on the root (`description`) |
| `see_also` | string (DN) | no | `null` | cross-reference (`seeAlso`) |
| `category` | string | no | `null` | classification tag (`businessCategory`) |
| `org` | string | no | `null` | organization-name tag (`o`) |
| `org_unit` | string | no | `null` | org-unit tag (`ou`) **on the entry** — a label, not the DN's structural `ou` |

### `roles`

Each entry is `{ name, description? }` and materializes a client-role child
`groupOfNames`. The client owns only the role *structure* — adding a role is a one-line
change; membership of each child is external (ignored), like the root.

## Outputs

| Name | Description |
| --- | --- |
| `dn` | full DN of the client root (`cn=<name>,<base_dn>`) |
| `cn` | the client's common name |
| `owner` | the owner DN (linked service account; also the seed member) |
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
