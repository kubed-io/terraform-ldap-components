# Role Example

Creates one realm role (`cn=admins,ou=roles,dc=example`) with two members, by
calling the [`role`](../../modules/role) module directly. The role is
authoritative over its `member` list.

```sh
tofu init
tofu apply
```

Configure the `ldap` provider block in [main.tf](main.tf) to point at your server
before applying.

## Kubernetes

Applies a `Role` composite resource ([role.yaml](role.yaml)). Crossplane reconciles it
into an OpenTofu Workspace that calls the same module — and, via `serviceAccountSelector`,
unions any labeled `ServiceAccount`'s `status.dn` into the authoritative member list.

```sh
kubectl apply -k .
```
