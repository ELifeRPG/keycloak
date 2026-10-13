# eliferpg/keycloak

Keycloak with the ELifeRPG providers baked in, published as **`ghcr.io/eliferpg/keycloak`**.

| Included | Source |
| --- | --- |
| Keycloak | `quay.io/keycloak/keycloak` (`FROM` in [`Dockerfile`](./Dockerfile)) |
| `link-bohemia-gameaccount` required action | [keycloak-bohemia-gameaccount](https://github.com/ELifeRPG/keycloak-bohemia-gameaccount) release jar |
| `eliferpg` theme (account, admin, email, login) | [keycloak-theme-eliferpg](https://github.com/ELifeRPG/keycloak-theme-eliferpg) release jar |

The image is pre-built (`kc.sh build`) with `KC_DB=postgres`, health endpoints, and the
`token-exchange` and `admin-fine-grained-authz` features, so run it with `start --optimized`.

## Updates

[Renovate](https://docs.renovatebot.com) opens a PR when Keycloak or either plugin publishes a
new release — the base image through its built-in Dockerfile support, the plugins through the
custom regex manager in [`renovate.json`](./renovate.json), which reads the
`# renovate: datasource=… depName=…` comment above each `ENV ELIFERPG_*_VERSION`.

CI ([`build.yml`](./.github/workflows/build.yml)) builds every PR and runs
[`scripts/smoke-test.sh`](./scripts/smoke-test.sh), which boots the image against Postgres and
checks through the admin API that both providers are actually loaded. Merging to `main` pushes
`:latest` and `:sha-<commit>`.

The provider SPI has no cross-version compatibility guarantee. The smoke test catches providers
that fail to load, not behavioural changes — review Keycloak minor/major bumps against the
plugin's own compatibility notes before merging.

## Local

```sh
docker build -t eliferpg/keycloak:dev .
scripts/smoke-test.sh eliferpg/keycloak:dev   # needs docker, curl, jq; SMOKE_PORT / SMOKE_MGMT_PORT to move ports
```
