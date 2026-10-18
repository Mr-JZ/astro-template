#!/usr/bin/env bash
set -euo pipefail

service_id="${1:?Usage: deploy-dokploy-service.sh <service-id>}"
poll_interval="${DOKPLOY_POLL_INTERVAL_SECONDS:-10}"
timeout_seconds="${DOKPLOY_DEPLOY_TIMEOUT_SECONDS:-1800}"

fetch_deployments() {
	curl --fail --silent --show-error \
		"${DOKPLOY_URL}/api/deployment.all?applicationId=${service_id}" \
		-H "x-api-key: ${DOKPLOY_TOKEN}"
}

latest_deployment_query='sort_by(.createdAt // "") | last // empty'
previous_deployment_id="$(
	fetch_deployments | jq -r "${latest_deployment_query} | .deploymentId // empty"
)"

curl --fail --silent --show-error -X POST \
	"${DOKPLOY_URL}/api/application.deploy" \
	-H "x-api-key: ${DOKPLOY_TOKEN}" \
	-H "Content-Type: application/json" \
	-d "{\"applicationId\":\"${service_id}\"}" >/dev/null

echo "Triggered Dokploy deployment for ${service_id}."

deadline=$((SECONDS + timeout_seconds))
target_deployment_id=""

while [ "$SECONDS" -lt "$deadline" ]; do
	deployments_json="$(fetch_deployments)"
	target_deployment_id="$(
		printf '%s' "$deployments_json" | jq -r \
			--arg previous_deployment_id "$previous_deployment_id" \
			"${latest_deployment_query}
			| select((.deploymentId // empty) != \$previous_deployment_id)
			| .deploymentId // empty"
	)"

	if [ -n "$target_deployment_id" ]; then
		break
	fi

	sleep "$poll_interval"
done

if [ -z "$target_deployment_id" ]; then
	echo "Timed out waiting for Dokploy to register a new deployment for ${service_id}." >&2
	exit 1
fi

echo "Waiting for Dokploy deployment ${target_deployment_id} to finish."

last_status=""

while [ "$SECONDS" -lt "$deadline" ]; do
	deployment_json="$(
		fetch_deployments | jq -c \
			--arg target_deployment_id "$target_deployment_id" \
			'map(select(.deploymentId == $target_deployment_id)) | first // empty'
	)"

	if [ -z "$deployment_json" ]; then
		sleep "$poll_interval"
		continue
	fi

	status="$(printf '%s' "$deployment_json" | jq -r '.status // "unknown"')"
	finished_at="$(printf '%s' "$deployment_json" | jq -r '.finishedAt // empty')"
	error_message="$(printf '%s' "$deployment_json" | jq -r '.errorMessage // empty')"

	if [ "$status" != "$last_status" ]; then
		echo "Dokploy deployment ${target_deployment_id} status: ${status}"
		last_status="$status"
	fi

	case "$status" in
		done | success | completed)
			echo "Dokploy deployment ${target_deployment_id} finished successfully."
			exit 0
			;;
		error | failed | canceled | cancelled)
			echo "Dokploy deployment ${target_deployment_id} failed." >&2
			if [ -n "$error_message" ]; then
				echo "$error_message" >&2
			fi
			exit 1
			;;
	esac

	if [ -n "$finished_at" ]; then
		echo "Dokploy deployment ${target_deployment_id} finished with unexpected status: ${status}" >&2
		if [ -n "$error_message" ]; then
			echo "$error_message" >&2
		fi
		exit 1
	fi

	sleep "$poll_interval"
done

echo "Timed out waiting for Dokploy deployment ${target_deployment_id} to finish." >&2
exit 1
