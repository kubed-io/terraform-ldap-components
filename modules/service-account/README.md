# ServiceAccount

Creates a single LDAP **service-account principal** — an `inetOrgPerson` +
`posixAccount` entry with a generated password. The RDN is `uid=<name>`, placed
under whatever `base_dn` you hand it (conventionally `ou=services,dc=<base>`).

A service account carries only its **identity + primary `gidNumber`**. It never
lists its own group/role/client membership — that edge always lives on the container
(a [`Group`](../group)'s `memberUid`, a [`Role`](../role)/[`Client`](../client)'s
`member`). See the [top-level README](../../README.md) for the two-planes model and
the membership rules.

## Variables

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `name` | string | no | workspace name | uid + cn; RDN is `uid=<name>`. Globally unique across users + services |
| `base_dn` | string | yes | — | parent DN the entry is created under |
| `posix.uidNumber` | string | yes | — | POSIX uidNumber; globally unique |
| `posix.gidNumber` | string | yes | — | PRIMARY group only |
| `posix.homeDirectory` | string | no | `/home/<name>` | POSIX homeDirectory |
| `posix.loginShell` | string | no | `/usr/sbin/nologin` | POSIX loginShell |
| `sn` | string | no | `<name>` | surname (required by `inetOrgPerson`) |
| `password` | string (sensitive) | no | `null` | bring-your-own `userPassword`; see below |
| `password_policy` | object | no | see below | `random_password` generation policy |
| `description` | string | no | `null` | human blurb (`description`) |
| `mail` | string | no | `null` | email address (`mail`) |

### `posix`

The unix-plane attributes — the `/etc/passwd` fields. `uidNumber`/`gidNumber` are
required; `gidNumber` is the **primary** group only. Supplementary group membership
is written by a [`Group`](../group), never here.

### Password — generated or supplied

By default the module **generates** the `userPassword` and exposes it as the
sensitive `password` output. To **bring your own** (e.g. a password already stored
elsewhere), set `password`: the module writes it verbatim, ignores `password_policy`,
and the `password` output is `null` (the caller already has it).

### `password_policy`

Passed straight to the [`random_password`][random_password] resource. Ignored when
`password` is supplied. Defaults are
production-safe — 16 characters with at least one of every character class, and a
shell-safe special set (no quotes, backslash, backtick, or `$` that break in env
files). `length` is validated to be `>= 16`.

| Key | Default |
| --- | --- |
| `length` | `16` |
| `special` / `numeric` / `upper` / `lower` | `true` |
| `minSpecial` / `minNumeric` / `minUpper` / `minLower` | `1` |
| `overrideSpecial` | `!#%&*()-_=+[]{}<>:?` |

## Outputs

| Name | Description |
| --- | --- |
| `dn` | full DN (`uid=<name>,<base_dn>`) |
| `username` | the uid (name); the connection Secret's `username` |
| `password` | generated `userPassword` (sensitive); `null` when one was supplied |
| `posix` | resolved `{ uidNumber, gidNumber, homeDirectory, loginShell }` (mirrors the input) |
| `mail` | email address, or `""` when unset |

## Example

```hcl
module "service_account" {
  source = "git::https://github.com/kubed-io/terraform-ldap-components.git//modules/service-account?ref=main"

  name    = "myapp"
  base_dn = "ou=services,dc=example"
  mail    = "myapp@example.com"
  posix = {
    uidNumber = "1050"
    gidNumber = "2001"
  }
}
```

A runnable version (using a local relative `source`) lives in
[`examples/service-account`](../../examples/service-account).

## References

- [OpenTofu LDAP Provider — `ldap_entry`](https://search.opentofu.org/provider/l-with/ldap/latest/docs/resources/entry)
- [`random_password`][random_password]
- [RFC 4519 — directory schema (`inetOrgPerson`)](https://www.rfc-editor.org/rfc/rfc4519)
- [RFC 2307 — `posixAccount` (NIS) schema](https://www.rfc-editor.org/rfc/rfc2307)

[random_password]: https://search.opentofu.org/provider/hashicorp/random/latest/docs/resources/password
