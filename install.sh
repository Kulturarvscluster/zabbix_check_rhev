#!/usr/bin/env bash

set -e
set -x

SCRIPT_DIR=$(dirname $(readlink -f $BASH_SOURCE[0]))

OVIRT=${1:-"root@kac-adm-002.kach.sblokalnet"}

echo $OVIRT

#(In the following, `kac-adm-002.kac.sblokalnet` is the host running the Ovirt Engine service. In Ovirt, a user `zabbix` with the role
#`readonlyAdmin` have been created.)

scp -p $SCRIPT_DIR/userparameter_ovirt-3.conf $OVIRT:/etc/zabbix/zabbix_agentd.d/userparameter_ovirt.conf

scp -p $SCRIPT_DIR/*.xslt $OVIRT:/var/lib/zabbix/


#Create a file `/var/lib/zabbix/.netrc` with this content and set permissions to 0700
grep "zabbix@internal" ~/.netrc | xargs -r -I{} ssh $OVIRT " ( cat /var/lib/zabbix/.netrc | grep '{}') || (echo '{}' | cat > /var/lib/zabbix/.netrc ) ; chmod go-rwx /var/lib/zabbix/.netrc; chown zabbix:zabbix /var/lib/zabbix/.netrc"


#Ensure that xsltproc and xmllint is installed
ssh $OVIRT sudo yum install -y libxslt libxml2

#Restart zabbix-agent and you are done
ssh $OVIRT systemctl restart zabbix-agent

#Thee zabbix-agent on this node will now be able to monitor stuff from ovirt.



#[root@pc543 ~]# zabbix_get -s kac-adm-002.kac.sblokalnet --tls-connect psk --tls-psk-identity YAKPSK --tls-psk-file ~/yakpsk.psk -k 'system.hostname'
