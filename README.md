# terraform-ldap-components

Crossplane CRDs and OpenTofu modules for managing a structured LDAP IAM topology
in a Kubernetes cluster. Provides typed Kubernetes resources that compose from a
low-level `Entry` primitive to create LDAP entries with consistent schemas,
generated credentials, and Kubernetes Secret publication.

Mirrors the pattern of `terraform-keycloak-components` and
`terraform-postgresql-postgresql`: each kind is a Crossplane Composite Resource
Definition (XRD) backed by an OpenTofu workspace.

## Kinds

Each kind lives under `crd/<kind>/` (XRD definition + composition + kustomization)
and has a corresponding OpenTofu module under `modules/<kind>/`.

### `ServiceAccount`

Creates a service-account principal under `ou=services,dc=<base>`.

- objectClasses: `inetOrgPerson`, `posixAccount`
- Generates a random password and publishes it as a Kubernetes Secret
- Joins posix `ou=groups` entries via `posixGroups` (written as `memberUid`)
- Joins pools and roles by carrying labels that a `Pool`'s `serviceAccountSelector`
  matches — the SA does not own a static member list

```yaml
apiVersion: ldap.kubed.io/v1alpha1
kind: ServiceAccount
metadata:
  name: myapp
spec:
  mail: myapp@example.com
  uidNumber: "1050"
  gidNumber: "2001"        # services primary group
  posixGroups:
  - cn=media,ou=groups,dc=example
  connectionSecret:
    namespace: myapp-ns
    name: myapp-ldap-creds
```

### `Group`

Creates a posix group under `ou=groups,dc=<base>` (unix plane — NAS, sshd,
application folder permissions).

- objectClass: `posixGroup`
- Holds `gidNumber` + `memberUid` (bare uid strings)
- Does **not** populate `memberOf` — posix groups are unix-plane only

```yaml
apiVersion: ldap.kubed.io/v1alpha1
kind: Group
metadata:
  name: media
spec:
  gidNumber: "2020"
  members:
  - alice
  - myapp
```

### `Team`

Creates a human cohort under `ou=teams,dc=<base>` (IAM plane).

- objectClass: `groupOfNames`
- Membership (`member`) uses full DNs → feeds the `memberOf` overlay → visible in
  Keycloak as a Group
- Use for organizational cohorts of humans; not for access gating (that is what
  `Pool` is for)

```yaml
apiVersion: ldap.kubed.io/v1alpha1
kind: Team
metadata:
  name: staff
spec:
  members:
  - uid=alice,ou=users,dc=example
  - uid=bob,ou=users,dc=example
```

### `Role`

Creates a realm-wide capability under `ou=roles,dc=<base>` (IAM plane).

- objectClass: `groupOfNames`
- Maps to a Keycloak **realm role**; each OIDC app is configured individually to
  honor it (opt-in, not automatic cascade)
- Membership feeds `memberOf` overlay; humans joined by external workflow, SAs by
  label selector

Common realm roles: `admins`, `editor`, `viewer` (+ optional `superadmin`, `guest`).

```yaml
apiVersion: ldap.kubed.io/v1alpha1
kind: Role
metadata:
  name: admins
spec: {}   # members are managed externally (workflow / SA selector)
```

### `Pool`

Creates a per-app login surface under `ou=pools,dc=<base>` (IAM plane). A pool is
the 1:1 counterpart to a Keycloak OIDC client.

- objectClass: `groupOfNames`
- Pool root membership = **access gate** ("may log in to this app")
- Each declared role becomes a child `groupOfNames` entry
  (`cn=<role>,cn=<pool>,ou=pools`) → maps to a Keycloak **client role**
- Membership is **dynamic**: service accounts join via `serviceAccountSelector`
  (label match, same pattern as the postgres `Server` CRD); humans are pushed in by
  external workflow
- Emits a matching Keycloak `OpenidClient` (1 pool = 1 client)
- `owner` links the pool back to the `ServiceAccount` that runs the app

One service account can own multiple pools (e.g. a CMS app owns one pool per site).

```yaml
apiVersion: ldap.kubed.io/v1alpha1
kind: Pool
metadata:
  name: myapp
spec:
  owner: uid=myapp,ou=services,dc=example
  roles:
  - name: admin
  - name: editor
  serviceAccountSelector:
    matchLabels:
      ldap.kubed.io/pool.myapp: "true"
  connectionSecret:
    namespace: myapp-ns
    name: myapp-ldap-pool-creds
```

## Module layout

```
modules/
├── service-account/   # OpenTofu module — inetOrgPerson+posixAccount under ou=services
├── group/             # OpenTofu module — posixGroup under ou=groups
├── team/              # OpenTofu module — groupOfNames under ou=teams
├── role/              # OpenTofu module — groupOfNames under ou=roles
└── pool/              # OpenTofu module — groupOfNames tree (root + role children) under ou=pools
crd/
├── service-account/   # XRD + Composition
├── group/
├── team/
├── role/
└── pool/
```

## Relationship to `ldap-entry`

The `ldap-entry` module (the generic `Entry` kind) is the **low-level primitive**
these typed kinds compose from. It handles the raw `ldap_entry` resource +
`random_password` + connection Secret publishing. The kinds in this repo are the
typed, opinionated layer on top.

## References

- [OpenTofu LDAP Provider](https://search.opentofu.org/provider/elastic-infra/ldap/latest)
- [OpenLDAP Overlays — memberOf](https://www.openldap.org/doc/admin24/overlays.html)
- [Crossplane Composite Resources](https://docs.crossplane.io/latest/concepts/composite-resources/)
