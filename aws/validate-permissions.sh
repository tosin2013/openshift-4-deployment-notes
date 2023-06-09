#!/bin/bash

# Get the list of Amazon EC2 permissions
permissions=$(aws iam list-permissions | jq -r '.Permissions[].PolicyArn')

# Check if ec2:AuthorizeSecurityGroupEgress permission is present
contains_permission=false
for permission in $permissions; do
    if [[ $permission == *":ec2:AuthorizeSecurityGroupEgress" ]]; then
        contains_permission=true
        break
    fi
done

# Output the result
if $contains_permission; then
    echo "The permission ec2:AuthorizeSecurityGroupEgress is present."
else
    echo "The permission ec2:AuthorizeSecurityGroupEgress is not present."
fi
