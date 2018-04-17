zabbix_check_rhev
=================

RHEV/oVirt checks for Zabbix

Install Guide
-------------

(In the following, `kac-adm-002.kac.sblokalnet` is the host running the Ovirt Engine service. In Ovirt, a user `zabbix` with the role
`readonlyAdmin` have been created.)

Copy `userparameter_ovirt.conf` to `/etc/zabbix/zabbix_agentd.d/`


Copy `zabbix_check_ovirt.py` to the zabbix agent's home (`/var/lib/zabbix`) and make the file executable

Create a file `/var/lib/zabbix/.netrc` with this content and set permissions to 0700

    machine kac-adm-002.kac.sblokalnet login zabbix@internal password INSERT_PASSWORD_HERE

Create the file `kac-adm-002.kac.sblokalnet.certs` by running `certs.sh` and copy the file to `/etc/zabbix/zabbix_agentd.d/`

Restart zabbix-agent and you are done

    systemctl restart zabbix-agent

Thee zabbix-agent on this node will now be able to monitor stuff from ovirt. 


Usage
-----
In the Zabbix webinterface, you can now create items with keys like 

    ovirt.statistics[<type>,<item>,<measure>]

or
    
    ovirt.direct[<type>,<item>,<measure>]

Here, the parameters are
* `<type>`: can be one of `host`, `vm` or `storage_domain`
* `<item>`: is the name of the thing in ovirt.
* `<measure>`: is the thing we want to measure

Examples are
* `ovirt.statistics[host,kac-man-001,memory.free]`: free memory for ovirt host kac-man-001
* `ovirt.statistics[vm,kac-abri-001,memory.used]`: Used memory for vm kac-abri-001
* `ovirt.direct[host,kac-man-001,summary/active]`: number of running VMs for host kac-man-001
* `ovirt.direct[storage_domain,sto-001,available]`: available space for storage domain sto-001


What can be measured depends on the type and on the key (statistics vs. direct). The `<measure>` key is intepreted as an xpath

To count the number of active VMs, you can do 

    ovirt.direct[host,kac-man-002,summary/active]
    
To see the xml you would xpath, inspect the Ovirt api returns from URLs like

* <https://kac-adm-002.kac.sblokalnet/ovirt-engine/api/hosts/>
* <https://kac-adm-002.kac.sblokalnet/ovirt-engine/api/vms/>
* <https://kac-adm-002.kac.sblokalnet/ovirt-engine/api/storagedomains/>


These are what I have identified as the most relevant measures

### host, statistics
From <https://kac-adm-002.kac.sblokalnet/ovirt-engine/api/hosts/a3a7ce16-799b-4a61-864e-ee8550efa677/statistics>

* 'memory.total'
* 'memory.used'
* 'memory.free'
* 'memory.shared'
* 'memory.buffers'
* 'memory.cached'
* 'swap.total'
* 'swap.free'
* 'swap.used'
* 'swap.cached'
* 'ksm.cpu.current'
* 'cpu.current.user'
* 'cpu.current.system'
* 'cpu.current.idle'
* 'cpu.load.avg.5m'
* 'boot.time'

### host, direct

From <https://kac-adm-002.kac.sblokalnet/ovirt-engine/api/hosts/a3a7ce16-799b-4a61-864e-ee8550efa677>

* 'summary/active': active VMs
* 'se_linux/mode'
* 'status'
* 'update_available'

\+ All the entries from __host, statistics__ 

### vm, statistics

From <https://kac-adm-002.kac.sblokalnet/ovirt-engine/api/vms/915925b6-99bb-4df1-84a9-42507a2caeac/statistics>

*  'memory.installed'
*  'memory.used'
*  'memory.buffered'
*  'memory.cached'
*  'memory.free'
*  'cpu.current.guest'
*  'cpu.current.hypervisor'
*  'cpu.current.total'
*  'migration.progress'

### vm, direct

From <https://kac-adm-002.kac.sblokalnet/ovirt-engine/api/vms/915925b6-99bb-4df1-84a9-42507a2caeac>

* 'status'
* 'memory'
* ...

### storage_domain

From <https://kac-adm-002.kac.sblokalnet/ovirt-engine/api/storagedomains/a597d0aa-bf22-47a3-a8a3-e5cecf3e20e0>

* 'available'
* 'used' 
* 'committed 
* 'external_status'  


### Ovirt Events and warnings

Not implemented yet. TODO



 