# Argo CD

Installs the upstream Argo CD Helm chart as the initial GitOps control plane
for a Kubernetes cluster.

The module pins chart `argo-cd` version `10.9.6` from the official Argo Helm
repository and records the archive digest in `module.yaml`. Its defaults keep
the server on a cluster-internal `ClusterIP` service and disable both HTTP and
gRPC ingress resources. Use a private access method, such as port forwarding
or a private tunnel, for initial administration.

The module supports DigitalOcean, AWS, Azure, and GCP clusters. Provider
infrastructure and cluster-specific access remain owned by the provider
repository and the client environment.
