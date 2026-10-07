# modules-kubernetes

The Helm charts referenced here can be installed through OPSd or directly
with Helm. This repository's module metadata, defaults, and schemas define an
OPSd contract; Helm itself does not read `module.yaml`. Provider-specific
integrations and defaults are identified per module.

Module definitions live under `modules/<layer>/<module-id>/`. Each records an
upstream chart source and version, an archive digest, OPSd defaults and a
module-values schema. The catalog lists the available module definitions.

## Component catalog

| Module | What it installs | What it does | OPSd provider scope and notes |
| --- | --- | --- | --- |
| [`argocd`](modules/bootstrap/argocd/README.md) | Upstream Argo CD Helm chart | Provides the cluster's GitOps control plane. Defaults keep its service internal and disable ingress. | DigitalOcean, AWS, Azure, GCP |
| [`cert-manager`](modules/infrastructure/cert-manager/README.md) | cert-manager Helm chart and CRDs | Automates certificate issuance and renewal. Issuers, Certificates, and DNS credentials are configured separately. | DigitalOcean, AWS, Azure, GCP |
| [`external-dns`](modules/infrastructure/external-dns/README.md) | ExternalDNS chart with a DigitalOcean webhook sidecar | Publishes DNS records for annotated Gateway API HTTPRoutes and Services. | DigitalOcean only; requires a separately created DNS token Secret. |
| [`external-secrets`](modules/infrastructure/external-secrets/README.md) | External Secrets Operator and CRDs | Syncs configured external secret stores into Kubernetes Secrets. The chart does not create credentials or stores. | OPSd integration currently lists DigitalOcean; the Secrets Manager webhook path is experimental. |

## DOKS-managed Gateway API

DigitalOcean Kubernetes provides Gateway API through its managed Cilium
implementation. It is available on VPC-native clusters running Kubernetes
1.33 or later, and its `GatewayClass` is named `cilium`. DOKS also manages the
Gateway API CRDs. Do not install a Gateway API or Cilium chart, or sync Gateway
API CRDs from this repository, for this integration. Modules in this repository
may create Gateway API resources after OPSd validates the cluster prerequisites;
they must leave the controller and CRD lifecycle to DOKS. See DigitalOcean's
[Gateway API guide](https://docs.digitalocean.com/products/kubernetes/how-to/use-gateway-api/)
and [Gateway API feature notes](https://docs.digitalocean.com/products/kubernetes/details/features/).

## Use with OPSd or directly with Helm

OPSd reads the module metadata, applies the module defaults, resolves the
versioned chart source, and records its digest in `opsd.lock.yaml`. OPSd also
adds manifest-derived settings for supported components. The CLI is optional:
to use a chart directly, read its module README, then install the upstream
chart with the pinned source and OPSd defaults plus your own values file:

```sh
helm upgrade --install <release> <chart> \
  --repo <repository> \
  --version <version> \
  --namespace <namespace> \
  --create-namespace \
  --values modules/<layer>/<module-id>/defaults.yaml \
  --values ./values.yaml
```

Replace the placeholders with the `spec.source` fields in `module.yaml` and
choose a namespace appropriate for the chart. Supply any required settings in
your own `values.yaml`; chart values and Kubernetes resources that OPSd normally
derives from the environment manifest, such as ExternalDNS domain filters and
TXT ownership ID, must be configured explicitly for a standalone install.
`schema.yaml` describes the module-values contract for OPSd and is not applied
automatically by Helm. To verify the exact archive in `module.yaml`, compare
its SHA-256 digest with `spec.source.digest` after downloading the pinned
chart version.

Module support metadata describes the combinations OPSd maintains, not an
upstream chart restriction. Check each module README for provider-specific
prerequisites, credentials, and resources that must be managed separately.

## Validate Helm modules without a cluster

Pull requests run `scripts/validate-helm-modules.rb`. The validator downloads
each pinned chart, checks its SHA-256 digest, runs `helm lint`, and renders its
manifests with `helm template`. These checks do not install charts or contact a
Kubernetes cluster. They catch chart packaging, value, and template errors;
only a live API server can confirm that the target cluster accepts every
rendered resource.

Run the same validation locally with Ruby 3.4.10 (in `.ruby-version`) and Helm
4.3.0 (in `.tool-versions`). It requires network access to download the pinned
chart archives; the script does not currently support offline validation. The
lint and template checks use Kubernetes version `1.25.0` and namespace
`argocd` for every chart, regardless of the module's target namespace:

```sh
ruby scripts/validate-helm-modules.rb
```

## Adding a module

1. Add `module.yaml`, `defaults.yaml`, `schema.yaml`, and a README under the
   directory for its canonical layer.
2. Add the module ID and metadata path to `catalog.yaml`.
3. For Helm sources, pin both the chart version and the SHA-256 digest of the
   downloaded chart archive. Keep only OPSd-supported values in defaults and
   schema; upstream defaults remain upstream-owned.
4. Run the Helm module validator and update this README when appropriate. The
   validator requires network access to pull chart archives.
