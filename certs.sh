#!/usr/bin/env bash

HOST=kac-adm-002.kac.sblokalnet

gnutls-cli --save-cert=$HOST.certs $HOST --insecure < /dev/null
