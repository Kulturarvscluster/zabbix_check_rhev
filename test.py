from zabbix_check_ovirt import get_from_statistics, get_directly

url = "https://kac-adm-002.kac.sblokalnet:443/ovirt-engine/api"
certs = "kac-adm-002.kac.sblokalnet.certs"
type = "host"
item="kac-man-001"
measure="memory.total"

print(get_from_statistics(url, certs, type, item, measure))


url = "https://kac-adm-002.kac.sblokalnet:443/ovirt-engine/api"
certs = "kac-adm-002.kac.sblokalnet.certs"
type = "vm"
item="kac-abri-001"
measure="memory.installed"

print(get_from_statistics(url, certs, type, item, measure))


url = "https://kac-adm-002.kac.sblokalnet:443/ovirt-engine/api"
certs = "kac-adm-002.kac.sblokalnet.certs"
type = "host"
item="kac-man-001"
measure="summary/active"

print(get_directly(url, certs, type, item, measure))



url = "https://kac-adm-002.kac.sblokalnet:443/ovirt-engine/api"
certs = "kac-adm-002.kac.sblokalnet.certs"
type = "storage_domain"
item="sto-001"
measure="available"

print(get_directly(url, certs, type, item, measure))
