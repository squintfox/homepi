#!/bin/bash

set -euo pipefail

STACK_NAME="homepi-critical"
SCRIPT_NAME="$(basename "$0")"

echo
echo "Stack processes for $STACK_NAME:"
echo
docker stack ps "$STACK_NAME" --no-trunc

echo
echo "Logs for $STACK_NAME:"
echo

pids=()

is_monitor_follower_pid() {
	local pid="$1"
	local cmd
	cmd="$(ps -p "$pid" -o args= 2>/dev/null || true)"
	[[ -n "$cmd" ]] || return 1
	[[ "$cmd" == *"docker service logs -f -n 20 --timestamps"* && "$cmd" == *"$STACK_NAME"* ]]
}

terminate_follower_pid() {
	local pid="$1"
	if kill -0 "$pid" 2>/dev/null; then
		pkill -TERM -P "$pid" 2>/dev/null || true
		kill "$pid" 2>/dev/null || true
	fi
}

cleanup_orphaned_followers() {
	# Kill stale monitor_critical.sh processes from previous runs (except this one).
	for shell_name in bash sh ash dash; do
		while IFS= read -r pid; do
			[[ "$pid" =~ ^[0-9]+$ ]] || continue
			if [[ "$pid" -ne "$$" ]]; then
				terminate_follower_pid "$pid"
				kill "$pid" 2>/dev/null || true
			fi
		done < <(pgrep -f "(/bin/)?${shell_name} .*${SCRIPT_NAME}" 2>/dev/null || true)
	done

	# Fallback: clean stale docker log followers for this stack.
	pkill -TERM -f "docker service logs -f -n 20 --timestamps ${STACK_NAME}_" 2>/dev/null || true
}

cleanup() {
	for pid in "${pids[@]}"; do
		terminate_follower_pid "$pid"
	done
}

handle_interrupt() {
	echo
	echo "Stopping log followers..."
	cleanup
	exit 130
}

trap handle_interrupt INT TERM
trap cleanup EXIT

cleanup_orphaned_followers

while IFS= read -r service; do
	docker service logs -f -n 20 --timestamps "$service" 2>&1 | while IFS= read -r line; do
		printf '[%s] %s\n' "$service" "$line"
	done &
	pids+=("$!")
done < <(docker stack services "$STACK_NAME" --format '{{.Name}}')

wait "${pids[@]}"
