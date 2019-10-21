# on PXE NODE 
#systemctl restart dhcpd
#systemctl status dhcpd


# on HA PROXY NODE
#sudo systemctl start haproxy
#sudo systemctl status haproxy

sudo virsh list 
sudo virsh start bootstrap

COMPUTERNAMES=" master-01 master-02 master-03 worker-01 worker-02"
for x in ${COMPUTERNAMES}
do 
  echo "Booting $x"
  sudo virsh start $x
  echo "waiting to deploy next node ..."
  sleep 30s
done 




openshift-install --dir=ocp4 wait-for bootstrap-complete --log-level debug

