# Group Example

Creates one POSIX group (`cn=media,ou=groups,dc=example`) with two members, by
calling the [`group`](../../modules/group) module directly.

```sh
tofu init
tofu apply
```

Configure the `ldap` provider block in [main.tf](main.tf) to point at your server
before applying.

## Kubernetes

Applies a `Group` composite resource ([group.yaml](group.yaml)). Crossplane reconciles
it into an OpenTofu Workspace that calls the same module.

```sh
kubectl apply -k .
```
