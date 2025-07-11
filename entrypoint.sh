#!/bin/bash
set -e

cd /u01/runner/actions-runner

# Check required environment
if [ -z "$RUNNER_NAME" ]; then
  echo "Missing required env: RUNNER_NAME"
  exit 1
fi

# Optional: allow override of token using env
TOKEN_FILE="/u01/runner/actions-runner/.runner-token"

# Save token if provided
if [ -n "$GITHUB_TOKEN" ]; then
  echo "$GITHUB_TOKEN" > "$TOKEN_FILE"
fi

# Load token if available
if [ -f "$TOKEN_FILE" ]; then
  GITHUB_TOKEN=$(cat "$TOKEN_FILE")
fi

# Check for URL (required to configure)
if [ -z "$GITHUB_URL" ]; then
  echo "Missing required env: GITHUB_URL"
  exit 1
fi

# If REMOVE_RUNNER=true or marker file exists, remove config
if [ "$REMOVE_RUNNER" == "true" ] || [ -f /u01/runner/remove-runner ]; then
  echo "Removing runner config..."
  if [ -f .runner ]; then
    ./config.sh remove --unattended --token "$GITHUB_TOKEN" || true
  fi
  rm -f .runner
  rm -f "$TOKEN_FILE"
  rm -f /u01/runner/remove-runner
fi

# Only configure if not already
if [ ! -f .runner ]; then
  echo "Configuring GitHub runner..."
  ./config.sh \
    --url "$GITHUB_URL" \
    --token "$GITHUB_TOKEN" \
    --name "$RUNNER_NAME" \
    --work "_work" \
    --labels docker,self-hosted,java \
    --unattended
else
  echo "Runner already configured. Skipping config."
fi

# Start runner
exec ./run.sh
