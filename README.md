zabbix_check_rhev
=================

RHEV/oVirt checks for Zabbix

Install Guide
-------------

(In the following, `kac-adm-002.kac.sblokalnet` is the host running the Ovirt Engine service. In Ovirt, a user `zabbix` with the role
`readonlyAdmin` have been created.)

Copy `userparameter_ovirt-3.conf` to `/etc/zabbix/zabbix_agentd.d/userparameter_ovirt.conf`

Copy the file `ovirt.discovery.xslt` to `/var/lib/zabbix/ovirt.discovery.xslt`

Create a file `/var/lib/zabbix/.netrc` with this content and set permissions to 0700

    machine kac-adm-002.kac.sblokalnet login zabbix@internal password INSERT_PASSWORD_HERE

Verify that the tools `xsltproc`,`xmllint` and `curl` are available to the zabbix user.


Restart zabbix-agent and you are done

    systemctl restart zabbix-agent

Thee zabbix-agent on this node will now be able to monitor stuff from ovirt. 


Usage
-----

The Ovirt autodiscovery for hosts or vms do NOT work as intended due to limitations in Zabbix, see <https://support.zabbix.com/browse/ZBXNEXT-2088>


You can now use these zabbix keys to get information about the oVirt hosts (hypervisors)

* `ovirt.hv.fqdn[<OVIRT_ENGINE>,<HOST_NAME>]`
* `ovirt.hv.hw.cpu.freq[<OVIRT_ENGINE>,<HOST_NAME>]`
* `ovirt.hv.hw.cpu.model[<OVIRT_ENGINE>,<HOST_NAME>]`
* `ovirt.hv.hw.cpu.num[<OVIRT_ENGINE>,<HOST_NAME>]`
* `ovirt.hv.hw.cpu.threads[<OVIRT_ENGINE>,<HOST_NAME>]`
* `ovirt.hv.hw.memory[<OVIRT_ENGINE>,<HOST_NAME>]`
* `ovirt.hv.hw.model[<OVIRT_ENGINE>,<HOST_NAME>]`
* `ovirt.hv.hw.uuid[<OVIRT_ENGINE>,<HOST_NAME>]`
* `ovirt.hv.hw.vendor[<OVIRT_ENGINE>,<HOST_NAME>]`
* `ovirt.hv.memory.used[<OVIRT_ENGINE>,<HOST_NAME>]`
* `ovirt.hv.version[<OVIRT_ENGINE>,<HOST_NAME>]`
* `ovirt.hv.vm.num[<OVIRT_ENGINE>,<HOST_NAME>]`

You can get the oVirt version directly with

* `ovirt.version[<OVIRT_ENGINE>]`

You can get info about the VMs with these keys

* `ovirt.vm.cpu.num[<OVIRT_ENGINE>,<VM_NAME>]`
* `ovirt.vm.memory.size[<OVIRT_ENGINE>,<VM_NAME>]`
* `ovirt.vm.net.if.in[<OVIRT_ENGINE>,<VM_NAME>,<IF_NAME>]`
* `ovirt.vm.net.if.out[<OVIRT_ENGINE>,<VM_NAME>,<IF_NAME>]`
