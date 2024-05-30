#!/bin/bash
# Documentation: https://docs.openshift.com/container-platform/4.15/updating/preparing_for_updates/preparing-manual-creds-update.html
declare VALIDATION=0
[ "$#" -eq 1 ] || die "OpenShift version to validate required, e,g 4.15.12"
VERSION=$1

if ! command -v oc &> /dev/null
then
    die "oc binary could not be found"
fi

# am I logged in
oc whoami &> /dev/null || die "Not logged into OpenShift" 

# Get release image
RELEASE_IMAGE=$(oc adm upgrade | awk '/VERSION     IMAGE/,0' |grep "${VERSION}" | awk '/quay.io\/openshift-release/ {print $2}')
#RELEASE_IMAGE="quay.io/openshift-release-dev/ocp-release@sha256:86575d1def95bc8944081b3201f1a7d9f408a5c966faf42f236c1dc83b6cc562"

if [[ -z "${RELEASE_IMAGE}" ]]; then
  echo "No upgrade path available for ${VERSION}" && exit 1
fi

WORK_DIR=$(mktemp -d)

# check if tmp dir was created
if [[ ! "$WORK_DIR" || ! -d "$WORK_DIR" ]]; then
  echo "Could not create temp dir"
  exit 1
fi

echo "Checking cluster can be upgraded to ${VERSION}"

oc adm release extract \
    --from="$RELEASE_IMAGE" \
    --credentials-requests \
    --included \
    --to="${WORK_DIR}"


for CREDENTIAL in "${WORK_DIR}"/*.yaml; do
    name=$(grep -b2 secretRef "${CREDENTIAL}"|awk '/name:/ {print $3}')
    namespace=$(grep -b2 secretRef "${CREDENTIAL}"|awk '/namespace:/ {print $3}')
    oc get secret "${name}" -n "${namespace}" &> /dev/null
    exists=$?
    if [[ $exists -ne 0 ]]; then    
        echo "Secret $name does not exist in $namespace" && VALIDATION=1
    fi
done

if [[ ${VALIDATION} ]]; then
  echo "Validation Passed!"
  echo "OpenShift can be upgraded to ${VERSION}"
  echo "Marking cloudcredential as upgradable to ${VERSION}"
  oc annotate cloudcredential cluster --overwrite=true cloudcredential.openshift.io/upgradeable-to="${VERSION}"
else 
  echo "Missing credentials cannot upgrade" && exit 1
fi

# deletes the temp directory
function cleanup {      
  rm -rf "$WORK_DIR"
  echo "Deleted temp working directory $WORK_DIR"
}

die () {
    echo >&2 "$@"
    exit 1
}

# register the cleanup function to be called on the EXIT signal
trap cleanup EXIT