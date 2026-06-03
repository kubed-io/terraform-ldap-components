# terraform-ldap-components

Crossplane CRDs and OpenTofu modules for managing a structured LDAP IAM topology
in a Kubernetes cluster. Typed Kubernetes resources produce LDAP entries with
consistent schemas, generated credentials, and Kubernetes Secret publication.

Mirrors `terraform-keycloak-components` and `terraform-postgresql-postgresql`:
each kind is a Crossplane Composite Resource Definition (XRD) backed by an
OpenTofu workspace (using the `l-with/ldap` provider's `ldap_entry` resource).

> Status: **design spec.** This README documents the intended schema and
> requirements of each kind and mocks the manifests. Implementation follows the
> spec below.

---

## Two planes

A thing's LDAP class is chosen by **which consumer reads it**, not by taste:

- **Unix plane** — real OS access: SSH, sudo, NAS shared-folder permissions.
  Consumers speak **posix** (`gidNumber` + `memberUid`). Does *not* feed `memberOf`
  or Keycloak. → `Group`.
- **IAM plane** — who you are / what you can do across apps. Consumers (Keycloak,
  and through it OIDC apps; plus `memberOf` login filters) speak **`groupOfNames`**
  (`member` = full DN), surfaced via the `memberof` overlay and federation. →
  `Team`, `Role`, `Client`.

Placement is **not** fixed by the module — every kind takes a `baseDn` (the parent
DN it is created under). The kind + module + LDAP schema guarantee the object is
consistent and meaningful *wherever* it lands; where it lands is as subjective as
LDAP itself. The layout below is a **conventional example**, not a hardcoded
structure:

```
dc=<base>                               # whatever base each resource's baseDn points at
├── ou=users        # human principals      (inetOrgPerson + posixAccount) — NOT managed here
├── ou=services     # ServiceAccount        (inetOrgPerson + posixAccount)
├── ou=groups       # Group   — posixGroup              (unix plane)
├── ou=teams        # Team    — groupOfNames            (IAM: Keycloak groups)
├── ou=roles        # Role    — groupOfNames            (IAM: Keycloak realm roles)
└── ou=clients      # Client  — groupOfNames + children (IAM: Keycloak clients + client roles)
```

---

## Cross-cutting requirements

These hold for **all** kinds and are the reason the schemas look the way they do.

1. **Global uid namespace.** `uid` and `uidNumber` are unique across `ou=users`
   *and* `ou=services`. A user and a service account may never share a name or
   number — posix `memberUid` is a bare string resolved by a flat subtree search
   and cannot disambiguate two OUs.
2. **Membership is stored container-side, once.** The edge lives as `member` (DN)
   on a `groupOfNames`, or `memberUid` (uid) on a `posixGroup` — on the group, never
   on the principal. A `ServiceAccount`/user holds only its identity and primary
   `gidNumber`; it **never lists its own groups/roles/clients** (not even posix). The
   reverse view (`memberOf` on the subject) is **derived** by the overlay. So
   `cn=friends` owns `memberUid: steven`; `steven` points at nothing.
3. **Exactly one writer per membership attribute.** Terraform owns a whole attribute
   and deletes anything not in its desired state, so TF and an external tool can't
   co-write the same `member`/`memberUid`. Each kind picks one writer:
   - **CRD-authoritative** (`Group`, `Role`): TF writes the full list — `Group` from
     `members`; `Role` from `members` ∪ `serviceAccountSelector`.
   - **Externally managed** (`Team`, `Client` + its client-role children): TF seeds
     `owner` then sets `ignore_attributes: [member]`; an external tool (n8n / the
     app) is the sole writer. No selector on these.

   `serviceAccountSelector` therefore lives only on the authoritative `Role` (and the
   postgres `Server`). No principal-side membership field exists in any case.
4. **`groupOfNames` requires ≥1 `member`** (RFC 4519). An empty team/role/client is
   schema-invalid; the composition seeds a sentinel `member` (a client seeds its
   `owner`) until a real member exists.
5. **No nested-group cascade.** `memberOf` is direct-only; OpenLDAP has no recursive
   match rule. A team listed as a `member` of a role is *informational intent* — for
   enforcement, flatten (controller writes effective members) or let Keycloak expand
   via composite roles. Only the client → client-role DIT parent/child is load-bearing.
6. **Placement is a parameter.** Every kind takes a `baseDn`; the module hardcodes
   no OU. The RDN is derived by the kind (`uid=<name>` for `ServiceAccount`,
   `cn=<name>` for the group-like kinds).

---

## Common fields

**`baseDn` (required, every kind)** — the parent DN the entry is created under.
Placement is a parameter; the module hardcodes no OU. The RDN is derived by the
kind (`uid=<name>` for `ServiceAccount`, `cn=<name>` for the group-like kinds), so
e.g. `baseDn: ou=services,dc=example` + `name: myapp` → `uid=myapp,ou=services,dc=example`.

Every kind also accepts these **optional** spec keys. The OpenTofu module maps each
to the corresponding LDAP attribute, **adding the auxiliary objectClass
automatically when the base class doesn't define it**. Omitted keys write nothing.

| CRD key | LDAP attribute | Applies to | objectClass added | Notes |
|---------|----------------|------------|-------------------|-------|
| `description` | `description` | all kinds | none (MAY on every base class) | human blurb |
| `owner` | `owner` (DN) | Team, Role, Client | none (`groupOfNames` MAY) | who administers it; `refint`-maintained. `Client` sets it to its SA. |
| `seeAlso` | `seeAlso` (DN) | Team, Role, Client | none | cross-reference to a related entry |
| `category` | `businessCategory` | Team, Role, Client | none | tag — environment, classification |
| `org` / `orgUnit` | `o` / `ou` | Team, Role, Client | none | tenant / grouping label |
| `url` | `labeledURI` | Client (any) | `labeledURIObject` (cosine) | app URL — analog of a Cognito managed-login domain |
| `email` | `mail` | Group, Team | `extensibleObject` | informational — see note |

**`email` is informational.** A typical LDAP mail server matches recipients by the
`mail` attribute and does **not** expand a group's members, so a group `email` acts
as a single alias, not a distribution list, unless the mail server is configured for
alias expansion / a list manager. Stored for documentation; don't assume fan-out.

**Policy-type settings are not these resources.** Password policy, MFA, account
recovery, login theme/branding → the Keycloak realm / OIDC client, not LDAP. These
kinds hold structure, membership, and the descriptive keys above.

---

## Kinds

Five kinds, each a standalone OpenTofu module under [`modules/`](modules) with a
runnable example under [`examples/`](examples) and (later) a Crossplane CRD under
`crd/`. Each module README is the detailed reference — variables, outputs, membership
behavior, and per-kind schema notes. This table is just the map.

| Kind | Module | Class / plane | Membership writer | Keycloak equivalent |
|------|--------|---------------|-------------------|---------------------|
| **ServiceAccount** | [`modules/service-account`](modules/service-account) | `inetOrgPerson`+`posixAccount` / both | n/a — identity only (+ generated/supplied password) | federated user / SA |
| **Group** | [`modules/group`](modules/group) | `posixGroup` / unix | **authoritative** — full `memberUid` from `members` | (none) |
| **Team** | [`modules/team`](modules/team) | `groupOfNames` / IAM | **external** — seeds `owner`, ignores `member` | group |
| **Role** | [`modules/role`](modules/role) | `groupOfNames` / IAM | **authoritative** — full `member` from `members` | realm role |
| **Client** | [`modules/client`](modules/client) | `groupOfNames` (+ role children) / IAM | **external** — seeds `owner`, ignores `member` | client (+ client roles) |

- **ServiceAccount** — a principal: identity + primary `gidNumber`, with a generated
  or bring-your-own password. Never lists its own memberships.
- **Group** — a posix group for the unix plane (NAS shares, sshd). Curated `members`,
  written in full by terraform.
- **Team** — a cohort of humans (WHO). Structure only; membership filled externally.
- **Role** — a realm-wide capability (WHAT). Terraform owns the full member list.
- **Client** — an app's login surface: root = access gate, role children = client
  roles. Structure only; membership filled externally; holds no secret.

See each module's README for the full variable/output reference and examples.

---

## Repo layout

```
modules/                # the OpenTofu modules (the source of truth for behavior)
├── service-account/    #   inetOrgPerson + posixAccount (+ password)
├── group/              #   posixGroup
├── team/               #   groupOfNames (external membership)
├── role/               #   groupOfNames (authoritative membership)
└── client/             #   groupOfNames root + role children
examples/               # runnable per-kind examples (local module source)
├── service-account/
├── group/
├── team/
├── role/
└── client/
crd/                    # Crossplane XRD + Composition per kind
├── _shared/            #   label-driven kustomize Component: common schema + wiring
├── service-account/    #   each kind: definition.yaml + composition.yaml + kustomization.yaml
├── group/
├── team/
├── role/               #   go-templating + ExtraResources selector (composition.tpl)
├── client/
└── kustomization.yaml  #   composes the five kinds
```

Each module ships `versions.tf` / `variables.tf` / `main.tf` / `outputs.tf`, a
`README.md`, and `tests/*.tftest.hcl` (run with `tofu test`). Each CRD pulls common
schema + composition wiring from `crd/_shared/` (a kustomize Component) by labeling its
definition/composition; see that dir for the label → injection map.


## References

- [OpenTofu LDAP Provider](https://search.opentofu.org/provider/l-with/ldap/latest)
- [OpenLDAP Overlays — memberOf](https://www.openldap.org/doc/admin24/overlays.html)
- [RFC 4519 — `groupOfNames` schema](https://www.rfc-editor.org/rfc/rfc4519)
- [Crossplane Composite Resources](https://docs.crossplane.io/latest/concepts/composite-resources/)
