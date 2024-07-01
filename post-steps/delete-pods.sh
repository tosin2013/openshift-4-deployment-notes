#!/bin/bash
set -xe
# Get all projects in OpenShift
projects=$(oc get projects -o=jsonpath='{.items[*].metadata.name}')

# Iterate through each project
for project in $projects; do
    echo "Checking project: $project"
    
    # Get pods with non-zero restarts in the current project
    oc get pods --field-selector=status.phase==Running -n $project --no-headers=true | while read line; do
        pod_name=$(echo $line | awk '{print $1}')
        restart_count=$(echo $line | awk '{print $4}')
        
        if [[ $restart_count != "0" ]]; then
            echo "Deleting pod: $pod_name in project: $project"
            oc delete pod $pod_name -n $project --force --grace-period=0
        else
            echo "No pods with restarts found in project: $project"
        fi
    done
done

