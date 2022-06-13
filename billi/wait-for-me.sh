bash -c 'while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' 192.168.150.116:8080)" != "200" ]]; do echo "status is not 200"; sleep 5; done'
