#!/usr/bin/env bash
#
# Variables needed for local development with Vault and Vault Reactor.

BUILD_PLATFORM=$(uname | tr "[:upper:]" "[:lower:]")
export BUILD_PLATFORM

export MINIKUBE_VERSION=v0.25.0
export KUBERNETES_VERSION=v1.8.0

export DEV_VAULT_VERSION=0.9.1
export DEV_VAULT_ADDR=http://vault:8200
export DEV_VAULT_TOKEN=vault-agent
export DEV_VAULT_PKI_COMMON_NAME=georgesre.network
export DEV_VAULT_PKI_ROLE=georgesre-internal
