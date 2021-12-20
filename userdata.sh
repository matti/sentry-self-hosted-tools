#!/usr/bin/env bash
# requires 4 cpu, 8gb ram says installer

set -euo pipefail

SENTRY_EMAIL=${SENTRY_EMAIL:-test@example.com}
SENTRY_PASSWORD=${SENTRY_PASSWORD:-password}
SENTRY_TAG="${SENTRY_TAG:-21.12.0}"
SENTRY_PROJECTS="${SENTRY_PROJECTS:-}"

cd /root

  apt-get update && apt-get upgrade -y
  apt-get install -y git screen socat

  if ! command -v docker; then
    curl -fsSL https://get.docker.com | sh
  fi

  if ! command -v docker-compose; then
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
  fi

  if [ ! -d self-hosted ]; then
    git clone https://github.com/matti/self-hosted
  fi

  cd self-hosted
    git checkout master
    set +e
      git branch delete -D latest
    set -e

    git fetch --all --tags
    git checkout "tags/${SENTRY_TAG}" -b latest

    if [ ! -d sentry/sentry-self-hosted-tools ]; then
      cd sentry
        git clone https://github.com/matti/self-hosted
      cd ..
    fi
    ./install.sh --no-user-prompt

    docker-compose up -d

    while true; do
      docker-compose exec -T web sentry createuser --email "${SENTRY_EMAIL}" --password "${SENTRY_PASSWORD}" --superuser && break
      sleep 1
    done

    for project in ${SENTRY_PROJECTS}; do
      name=$(echo $project | cut -d: -f1)
      id=$(echo $project | cut -d: -f2)

      echo "name: $name"
      echo "id: $id"

      docker-compose exec -T web sentry exec /etc/sentry/sentry-self-hosted-tools/project-create-static.py --name "${name}" --id "${id}"
    done
    screen -dmS fwd-80-to-9000 /usr/bin/socat TCP-LISTEN:80,fork TCP:127.0.0.1:9000