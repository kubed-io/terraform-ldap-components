# Team Example

Creates one IAM-plane team (`cn=staff,ou=teams,dc=example`) by calling the
[`team`](../../modules/team) module directly. The `owner` is seeded as the initial
member; real membership is filled by an external tool (terraform ignores `member`).

```sh
tofu init
tofu apply
```

Configure the `ldap` provider block in [main.tf](main.tf) to point at your server
before applying.

## Kubernetes

Applies a `Team` composite resource ([team.yaml](team.yaml)). Crossplane reconciles it
into an OpenTofu Workspace that calls the same module.

```sh
kubectl apply -k .
```
