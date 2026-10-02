# modules-kubernetes

Provider-neutral Kubernetes platform modules for OPSd environments.

Official modules live under `modules/<layer>/<module-id>/`. Each module pins
its upstream source and keeps its OPSd defaults and JSON Schema beside the
metadata. The catalog lists the module metadata files available in this repo.

## Modules

- [`argocd`](modules/bootstrap/argocd/README.md) installs Argo CD as the
  cluster's initial GitOps control plane.

## Validate Helm modules without a cluster

Pull requests run `scripts/validate-helm-modules.rb`. The validator downloads
each pinned chart, checks its SHA-256 digest, runs `helm lint`, and renders its
manifests with `helm template`. These checks do not install charts or contact a
Kubernetes cluster. They catch chart packaging, value, and template errors;
only a live API server can confirm that the target cluster accepts every
rendered resource.

Run the same validation locally with Ruby 3.4.10 (in `.ruby-version`) and Helm
4.3.0 (in `.tool-versions`):

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
4. Run the offline Helm validator and update this README when appropriate.
