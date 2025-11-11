#!/bin/bash
set -e

# Detect environment and set OPENPROJECT_HOST__NAME
if [ -f /etc/this-is-guardeloo-staging ] || [ -f /etc/this-is-smp-staging ]; then
  export OPENPROJECT_HOST__NAME="staging-pm.guard-e-loo.co.uk"
  echo "OpenProject configured for STAGING: $OPENPROJECT_HOST__NAME"
elif [ -f /etc/this-is-guardeloo-production ] || [ -f /etc/this-is-smp-production ]; then
  export OPENPROJECT_HOST__NAME="pm.guard-e-loo.co.uk"
  echo "OpenProject configured for PRODUCTION: $OPENPROJECT_HOST__NAME"
else
  export OPENPROJECT_HOST__NAME="${OPENPROJECT_HOST:-localhost:8082}"
  echo "OpenProject configured for DEVELOPMENT: $OPENPROJECT_HOST__NAME"
fi

# Call the original OpenProject entrypoint
exec /app/docker/prod/entrypoint.sh "$@"

