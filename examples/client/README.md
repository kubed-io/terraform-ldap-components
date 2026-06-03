# Client Example

Creates one app login surface (`cn=nextcloud,ou=clients,dc=example`) with two client
roles (`admin`, `media-manager`), by calling the [`client`](../../modules/client) module
directly. The owner is seeded as the initial member on the root and each role child;
real membership is filled by an external tool (terraform ignores `member`).

```sh
tofu init
tofu apply
```

Configure the `ldap` provider block in [main.tf](main.tf) to point at your server
before applying.

## Kubernetes

Applies a `Client` composite resource ([client.yaml](client.yaml)). Crossplane reconciles
it into an OpenTofu Workspace that calls the same module (root + client-role children).

```sh
kubectl apply -k .
```
