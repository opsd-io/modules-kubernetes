# ExternalDNS

Installs ExternalDNS with the DigitalOcean webhook provider as a sidecar. The
ExternalDNS chart and webhook image are pinned. The webhook project is an
independently maintained community project, not an ExternalDNS-maintainer
endorsed provider.

ExternalDNS watches Gateway API `HTTPRoute` resources and Services. Set the
`external-dns.kubernetes.io/hostname` annotation on each route or Service whose
DNS name it should manage. Gateway API route targets are resolved from the
parent Gateway status address. Gateway listener hostnames by themselves do not
declare a DNS record.

The module uses TXT ownership records and defaults to `upsert-only`, so it
creates or updates records without deleting records when a source disappears.
Set a unique `txtOwnerId` per cluster and restrict `domainFilters` to zones this
cluster is allowed to manage. Create the token Secret separately in the
`external-dns` namespace, with key `access-token`; never place the token in
module values or generated manifests.
