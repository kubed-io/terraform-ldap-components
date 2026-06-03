# ServiceAccount Example

Creates one LDAP service account (`uid=myapp,ou=services,dc=example`) with a
generated password, by calling the [`service-account`](../../modules/service-account)
module directly.

```sh
tofu init
tofu apply
```

Configure the `ldap` provider block in [main.tf](main.tf) to point at your server
before applying. The generated password is exposed as a sensitive output:

```sh
tofu output -raw password
```

## Kubernetes

Applies a `ServiceAccount` composite resource ([serviceaccount.yaml](serviceaccount.yaml)).
Crossplane reconciles it into an OpenTofu Workspace that calls the same module and
publishes the connection secret (keys `username`, `password`).

```sh
kubectl apply -k .
```
