# Keycloak with the ELifeRPG providers, pre-built (`kc.sh build`) for `start --optimized`.
#
# Versions are bumped by Renovate: the base image by its dockerfile manager, the plugins by the
# custom regex manager in renovate.json (the `# renovate:` comment above each ENV). The ENVs stay
# in the image, so `docker inspect` shows which plugin versions it contains.
# The provider SPI carries no cross-version compatibility guarantee, so a bump only ships once
# CI's smoke test (scripts/smoke-test.sh) has loaded the providers into the new combination.

FROM quay.io/keycloak/keycloak:26.8.1

# renovate: datasource=github-releases depName=ELifeRPG/keycloak-bohemia-gameaccount
ENV ELIFERPG_BOHEMIA_GAMEACCOUNT_VERSION=1.1.0
# renovate: datasource=github-releases depName=ELifeRPG/keycloak-theme-eliferpg
ENV ELIFERPG_THEME_VERSION=1.0.1

ADD --chown=keycloak:keycloak \
    https://github.com/ELifeRPG/keycloak-bohemia-gameaccount/releases/download/${ELIFERPG_BOHEMIA_GAMEACCOUNT_VERSION}/keycloak-bohemia-gameaccount-${ELIFERPG_BOHEMIA_GAMEACCOUNT_VERSION}.jar \
    /opt/keycloak/providers/keycloak-bohemia-gameaccount.jar
# The theme repo tags with a `v` prefix; Keycloak 26 needs its "all other versions" build.
ADD --chown=keycloak:keycloak \
    https://github.com/ELifeRPG/keycloak-theme-eliferpg/releases/download/v${ELIFERPG_THEME_VERSION}/keycloak-theme-for-kc-all-other-versions.jar \
    /opt/keycloak/providers/keycloak-theme-eliferpg.jar

ENV KC_DB=postgres \
    KC_HEALTH_ENABLED=true \
    KC_FEATURES=token-exchange,admin-fine-grained-authz
RUN /opt/keycloak/bin/kc.sh build
