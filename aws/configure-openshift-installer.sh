#!/bin/bash
curl -OL https://gist.githubusercontent.com/tosin2013/6274b9f93bcd89da8a91abc8eccb5980/raw/4dcf916aefa93ffff559f9e54a61af16359ec981/.tmux.conf -o ~/.tmux.conf


ssh-keygen -t rsa -b 4096 -f ~/.ssh/cluster-key -N ''

chmod 400 ~/.ssh/cluster-key .pub
cat  ~/.ssh/cluster-key.pub

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/cluster-key 

echo " go to https://cloud.openshift.com/clusters/install"

read -p "Press [Enter] Once you have your pull secert..."

echo "tail -f ${HOME}/cluster/.openshift_install.log in a new tab or terminal"
sleep 3s

openshift-install create cluster --dir $HOME/cluster --log-level debug
