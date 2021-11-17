#!/bin/bash

#########################################################
## Query the Assisted Installer Service for supported 
##  versions
echo "===== Querying the Assisted Installer Service for supported versions..."

QUERY_CLUSTER_VERSIONS_REQUEST=$(curl -s --fail \
--header "Authorization: Bearer $ACTIVE_TOKEN" \
--header "Content-Type: application/json" \
--header "Accept: application/json" \
--request GET \
"${ASSISTED_SERVICE_V1_API}/openshift_versions")

if [ -z "$QUERY_CLUSTER_VERSIONS_REQUEST" ]; then
  echo "===== Failed to find supported cluster release version!"
  exit 1
fi

export CLUSTER_RELEASE=$(printf '%s' "$QUERY_CLUSTER_VERSIONS_REQUEST" | jq -r '.["'"${CLUSTER_VERSION}"'"].display_name')
echo -e "  Found Cluster Release ${CLUSTER_RELEASE} from target version ${CLUSTER_VERSION}\n"