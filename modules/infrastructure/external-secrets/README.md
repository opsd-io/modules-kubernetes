# External Secrets Operator

Installs External Secrets Operator (ESO) and its CRDs. Install it once per
cluster before applying `SecretStore` and `ExternalSecret` resources. The module
does not create credentials or secret stores.

## DigitalOcean Secrets Manager

ESO has no native DigitalOcean Secrets Manager provider. A spike can use ESO's
generic webhook provider to read a named secret from DigitalOcean's API. The
API path used by `doctl` is `GET /v2/security/secrets/{name}?region={region}`;
the response contains secret values under `values`. This endpoint is not
documented in DigitalOcean's public API reference, so this integration is
experimental and may change without notice. It has not been qualified against
a live DigitalOcean account. Do not use it for production workloads until a
live end-to-end test and an API support commitment are available.

The webhook SecretStore is specific to one DigitalOcean secret container and
region. Set the URL to that container and region, use a read-only DigitalOcean
personal access token in the `Authorization: Bearer` header, and extract the
required property from `$.values.<property>`. Keep the `ExternalSecret`'s
`remoteRef.key` equal to the DigitalOcean secret value key. ESO's webhook
provider requires every referenced credential Secret to have the label
`external-secrets.io/type: webhook`.

Bootstrap the token outside GitOps, for example by creating a Kubernetes Secret
in the namespace where the `SecretStore` runs. Never put the token in chart
values, a checked-in manifest, or an unencrypted repository file. Restrict the
token to read-only access where DigitalOcean exposes a suitable scope, and
rotate it through the same manual bootstrap process. ESO then writes the
selected values as Kubernetes Secrets; workloads consume those local Secrets.

Because the DigitalOcean endpoint lacks a published API contract, this path is
not a supported native ESO provider. If that limitation is unacceptable, keep
credentials in Kubernetes Secrets and use SOPS-encrypted manifests as an
explicit optional GitOps fallback. SOPS requires a separately managed
decryption key and does not synchronize from DigitalOcean Secrets Manager.

References: [ESO webhook provider](https://external-secrets.io/latest/provider/webhook/),
[DigitalOcean `doctl secrets`](https://docs.digitalocean.com/reference/doctl/reference/secrets/),
[DigitalOcean `doctl secrets get`](https://docs.digitalocean.com/reference/doctl/reference/secrets/get/),
[the `doctl` implementation of its Secrets API client](https://github.com/digitalocean/doctl/blob/main/vendor/github.com/digitalocean/godo/secrets.go).
