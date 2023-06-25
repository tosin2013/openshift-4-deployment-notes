#!/bin/bash
set -xe 
aws ec2 authorize-security-group-egress \
--group-id 1 \
--protocol tcp \
--port 80 \
--cidr 0.0.0.0/0 \
--dry-run 


