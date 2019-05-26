#!/usr/bin/env bash
#
# A collection of functions for working with Minikube, Kubernetes, and Vault.


# Execute a remote Vault command inside the 'vault' Kubernetes pod
alias run_vault="kubectl exec -it vault -- vault"


##############################################################################
# Check that the given command exists
# Arguments:
#   cmd: Command to check
# Returns:
#   (boolean) If command exists
##############################################################################
command_exists() {
  local cmd="$1"

  type "$cmd" &> /dev/null
}


##############################################################################
# Ensure that Minikube is installed and running
# Arguments:
#   minikube_version:   Version of Minikube to install
#   build_platform:     Build platform to use
#   kubernetes_version: Version of Kubernetes to install
# Returns:
#   None
##############################################################################
ensure_minikube_installed_and_running() {
  local minikube_version="$1"
  local build_platform="$2"
  local kubernetes_version="$3"

  echo "Checking for minikube on system"
  if ! command_exists minikube; then
    echo "Minikube not found. Installing..."
    curl -Lo minikube "https://storage.googleapis.com/minikube/releases/${minikube_version}/minikube-${build_platform}-amd64" && \
      chmod +x minikube && \
      sudo mv minikube /usr/local/bin/
  else
    echo "Minikube is present. Skipping installation."
  fi

  # The output format of 'minikube status' tends to change between Minikube
  # versions. The absence of the word "Running" in the command output should be
  # enough to confirm that the Minikube VM is not running.
  if ! minikube status | grep "Running" > /dev/null; then
    echo "Starting Minikube..."
    minikube start --kubernetes-version "$kubernetes_version"
  fi
}


##############################################################################
# Ensure that Kubernetes is running or exit on timeout
# Arguments:
#   timeout: How long to wait for Kubernetes to start (default 30 seconds)
# Returns:
#   None
##############################################################################
ensure_kubernetes_running() {
  local timeout=${1:-"30"}

  local counter=0

  while true; do
    echo "Waiting for Kubernetes to boot (${counter}s)"
    if kubectl cluster-info 2>&1 echo; then
      echo "Kubernetes has started up"
      break
    fi

    if [ "$counter" -gt "$timeout" ]; then
      echo "Timed out waiting for Kubernetes to start"
      exit 1
    fi

    sleep 5
    counter=$((counter + 5))
  done
}


##############################################################################
# Ensure that a Kubernetes pod is running or exit on timeout
# Arguments:
#   pod_name: Name of Kubernetes pod
#   timeout:  How long to wait for pod to start (default 300 seconds)
# Returns:
#   None
##############################################################################
ensure_pod_running() {
  local pod_name="$1"
  local timeout=${2:-"300"}

  local counter=0

  while true; do
    echo "Waiting for ${pod_name} pod to boot (${counter}s)"
    if kubectl get pod "${pod_name}" | grep "Running" > /dev/null ; then
      echo "${pod_name} pod is running"
      break
    fi

    if [ "$counter" -gt "$timeout" ]; then
      echo "Timed out starting ${pod_name} pod"
      exit 1
    fi

    sleep 5
    counter=$((counter + 5))
  done
}


##############################################################################
# Ensure that a Kubernetes pod is deleted or exit on timeout
# Arguments:
#   pod_name: Name of Kubernetes pod
#   timeout:  How long to wait for pod to be deleted (default 60 seconds)
# Returns:
#   None
##############################################################################
ensure_pod_deleted() {
  local pod_name="$1"
  local timeout=${2:-"60"}

  local counter=0

  while true; do
    echo "Waiting for existing ${pod_name} pod to be deleted (${counter}s)"
    if ! kubectl get pod "${pod_name}" > /dev/null 2>&1 ; then
      echo "${pod_name} pod has been deleted"
      break
    fi

    if [ "$counter" -gt "$timeout" ]; then
      echo "Timed out waiting for existing ${pod_name} pod to be deleted"
      exit 1
    fi

    sleep 5
    counter=$((counter + 5))
  done
}


##############################################################################
# Ensure that the Vault service is running or exit on timeout
# Arguments:
#   timeout: How long to wait for Vault to start (default 30 seconds)
# Returns:
#   None
##############################################################################
ensure_vault_service_available() {
  local timeout=${1:-"30"}

  local counter=0

  while true; do
    echo "Waiting for Vault service to become available (${counter}s)"
    if run_vault status | grep "Sealed" | grep "false" > /dev/null; then
      echo "Vault service is available"
      break
    fi

    if [ "$counter" -gt "$timeout" ]; then
      echo "Timed out starting vault service"
      exit 1
    fi

    sleep 5
    counter=$((counter + 5))
  done
}
