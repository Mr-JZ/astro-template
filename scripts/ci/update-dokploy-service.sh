#!/usr/bin/env bash
set -euo pipefail

service_id="${1:?Usage: update-dokploy-service.sh <service-id> <image>}"
image="${2:?Usage: update-dokploy-service.sh <service-id> <image>}"

body=$(jq -n \
	--arg id "$service_id" \
	--arg image "$image" \
	--arg registry_url "$REGISTRY_HOST" \
	--arg username "x-token" \
	--arg password "$DEPOT_PULL_TOKEN" \
	'{
		applicationId: $id,
		dockerImage: $image,
		registryUrl: $registry_url,
		username: $username,
		password: $password
	}')

curl --fail --silent --show-error -X POST \
	"${DOKPLOY_URL}/api/application.saveDockerProvider" \
	-H "x-api-key: ${DOKPLOY_TOKEN}" \
	-H "Content-Type: application/json" \
	-d "$body" >/dev/null
