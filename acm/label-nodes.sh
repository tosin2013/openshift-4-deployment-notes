#!/bin/bash 

#!/bin/bash

# Function to label a node using oc command
label_node() {
    local node_name="$1"
    oc label node "$node_name" node-role.kubernetes.io/infra=""
}

# Main script
echo "Enter computer names (press Ctrl+D to finish):"

while read -r node_name; do
    label_node "$node_name"
done

echo "Labeling complete."
