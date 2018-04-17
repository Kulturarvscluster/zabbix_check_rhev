#!/usr/bin/env python
# coding=utf-8
import argparse
from xml.etree.ElementTree import fromstring

import requests


def urljoin(*args):
    """
    Joins given arguments into a url. Trailing but not leading slashes are
    stripped for each argument.
    """
    return "/".join(map(lambda x: str(x).rstrip('/'), args))


def get_from_statistics(url, certs, type, item, measure):
    id = find_id_of_item(url, certs, item, type)
    statistics_url = urljoin(url, type.replace("_", "") + 's', id, 'statistics')
    statistics = requests.get(statistics_url, verify=certs)
    xml = fromstring(statistics.text)
    measured = xml.findtext(".//statistic[name='" + measure + "']/values/value/datum")
    return measured


def get_directly(url, certs, type, item, measure):
    id = find_id_of_item(url, certs, item, type)
    item_url = urljoin(url, type.replace("_", "") + 's', id)
    item_details = requests.get(item_url, verify=certs)
    xml = fromstring(item_details.text)
    measured = xml.findtext(".//" + measure)
    return measured


def find_id_of_item(url, certs, item, type):
    fullUrl = urljoin(url, type.replace("_", "") + 's')
    response = requests.get(fullUrl,
                            verify=certs,
                            params={'search': item},
                            headers={'Accept': 'application/json'}
                            ).json()

    id = response[type][0]['id']
    return id


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Query ovirt')
    parser.add_argument('--url', help='Url to the ovirt api endpoint', default="localhost")
    parser.add_argument('--certs', help='Path to the CA_BUNDLE file with https certificates', default=None)

    parser.add_argument('--statistics', action='store_true', help='Use the statistics element')
    parser.add_argument('type', help='One of "vm","host" or "storage_domain')
    parser.add_argument('item', help='The Item to get')

    parser.add_argument('measure', help='The thing to measure')
    args = parser.parse_args()
    if args.statistics:
        print(get_from_statistics(args.url, args.certs, args.type, args.item, args.measure))
    else:
        print(get_directly(args.url, args.certs, args.type, args.item, args.measure))
