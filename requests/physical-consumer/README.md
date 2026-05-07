# JAD Physical Consumer Bruno Collection - Dynamic Provider

Use this collection when the physical consumer runs in namespace `consumer` and the virtual JAD connector runs in namespace `edc-v`.

## Port-forwardings

Run these before using Bruno:

```bash
kubectl port-forward -n consumer deployment/controlplane 9081:8081
kubectl port-forward -n edc-v deployment/controlplane 18081:8081
kubectl port-forward -n edc-v deployment/keycloak 8180:8080
kubectl port-forward -n edc-v svc/dataplane 11002:11002
```

## Environment

Select: `local`.

## Dynamic provider discovery

Run `01 Discover Virtual Providers`. It calls the virtual JAD control plane:

```text
{{virtualCpBaseUrl}}/v5beta/participants?offset=0&limit=100
```

It then selects a provider candidate and saves:

```text
providerParticipantId
providerDid
providerProtocolUrl
```

By default it filters for participant IDs/DIDs containing `provider`. If you have multiple providers, set `providerFilter`, `providerIndex`, or `preferredProviderParticipantId` in the `local` environment.

## Run order

1. `00 Get Management Token`
2. `01 Discover Virtual Providers`
3. `02 Get Consumer Assets`
4. `03 Request Provider Catalog`
5. `04 Initiate Contract Negotiation`
6. Re-run `05 Get Contract Negotiation By ID` until `FINALIZED`
7. `06 Get Contract Agreement`
8. `07 Initiate Transfer`
9. Re-run `08 Get Transfer Process By ID` until `STARTED`
10. `09 Query Cached EDRs`
11. `10 Get EDR DataAddress`
12. `11 Download Data`
13. Optional: `12 Debug Saved Variables`
