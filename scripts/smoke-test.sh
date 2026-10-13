#!/usr/bin/env bash
# Boots the image against a throwaway Postgres and asserts Keycloak actually loaded the ELifeRPG
# providers: the `link-bohemia-gameaccount` required action and the `eliferpg` login theme.
#
#   scripts/smoke-test.sh <image>
set -euo pipefail

IMAGE=${1:?usage: smoke-test.sh <image>}
NAME=kc-smoke-$$
PORT=${SMOKE_PORT:-18080}
MGMT_PORT=${SMOKE_MGMT_PORT:-19000}

cleanup() {
  docker rm -f "$NAME-kc" "$NAME-pg" >/dev/null 2>&1 || true
  docker network rm "$NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker network create "$NAME" >/dev/null
docker run -d --name "$NAME-pg" --network "$NAME" --network-alias postgres \
  -e POSTGRES_PASSWORD=smoke postgres:17 >/dev/null
until docker exec "$NAME-pg" pg_isready -U postgres -h 127.0.0.1 >/dev/null 2>&1; do sleep 1; done

docker run -d --name "$NAME-kc" --network "$NAME" \
  -p "127.0.0.1:$PORT:8080" -p "127.0.0.1:$MGMT_PORT:9000" \
  -e KC_DB_URL=jdbc:postgresql://postgres:5432/postgres \
  -e KC_DB_USERNAME=postgres -e KC_DB_PASSWORD=smoke \
  -e KC_HOSTNAME=http://localhost:$PORT -e KC_HTTP_ENABLED=true \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
  "$IMAGE" start --optimized >/dev/null

for _ in $(seq 1 90); do
  curl -fs "http://127.0.0.1:$MGMT_PORT/health/ready" >/dev/null 2>&1 && break
  sleep 2
done
if ! curl -fs "http://127.0.0.1:$MGMT_PORT/health/ready" >/dev/null; then
  docker logs "$NAME-kc" | tail -50
  echo "FAIL: Keycloak did not become ready" >&2
  exit 1
fi

TOKEN=$(curl -fs "http://127.0.0.1:$PORT/realms/master/protocol/openid-connect/token" \
  -d grant_type=password -d client_id=admin-cli -d username=admin -d password=admin | jq -r .access_token)
INFO=$(curl -fs -H "Authorization: Bearer $TOKEN" "http://127.0.0.1:$PORT/admin/serverinfo")

fail=0
jq -e '.providers["required-action"].providers | has("link-bohemia-gameaccount")' <<<"$INFO" >/dev/null \
  && echo "ok: required action link-bohemia-gameaccount" \
  || { echo "FAIL: required action link-bohemia-gameaccount not loaded" >&2; fail=1; }
jq -e '[.themes.login[].name] | index("eliferpg")' <<<"$INFO" >/dev/null \
  && echo "ok: login theme eliferpg" \
  || { echo "FAIL: login theme eliferpg not loaded" >&2; fail=1; }
exit $fail
