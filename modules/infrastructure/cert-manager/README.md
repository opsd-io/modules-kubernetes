# cert-manager

Installs cert-manager and its CRDs for Kubernetes certificate automation.
Install this module once per cluster. DNS provider credentials and Issuer or
Certificate resources are managed separately; never store provider tokens in
module values.

The pinned chart enables CRD installation. For DigitalOcean DNS-01, create a
Secret in cert-manager's Cluster Resource Namespace and reference it from an
ACME `ClusterIssuer` using cert-manager's native DigitalOcean solver.
