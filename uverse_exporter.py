#!/usr/bin/env python

import argparse
import logging
import time

from prometheus_client import start_http_server
from prometheus_client.core import CounterMetricFamily, REGISTRY
import requests
from bs4 import BeautifulSoup

logger = logging.getLogger(__name__)

class BroadbandStats(object):
    def __init__(self, base_url="http://192.168.1.1"):
        self.url = base_url+"/cgi-bin/broadbandstatistics.ha"

    def collect(self):
        logger.info(f"fetching stats from {self.url}")
        r = requests.get(self.url)
        r.raise_for_status
        s = BeautifulSoup(r.text,"html.parser")

        t=s.find(summary="Ethernet IPv4 Statistics Table")
        if not t:
            logger.error("Statistics table not found")
            return {}

        d={}
        for row in t.find_all("tr"):
           d[row.find("th").text] = int(row.find("td").text)

        return d

def stat_to_metric(name):
    return name.lower().replace(" ","_")

class StatsCollector(object):
    def __init__(self, base_url=None):
        if base_url:
            self.broadband_stats = BroadbandStats(base_url)
        else:
            self.broadband_stats = BroadbandStats()

    def collect(self):
        for k,v in self.broadband_stats.collect().items():
            yield CounterMetricFamily(f"att_broadband_{stat_to_metric(k)}_total",k,value=v)


if __name__=="__main__":
    parser = argparse.ArgumentParser(description="AT&T/Uverse metrics exporter")
    parser.add_argument("-u","--url",default="http://192.168.1.1")
    parser.add_argument("-p","--port",type=int,default=8080)
    parser.add_argument("-v","--verbose",dest="log_level",action="store_const",
                        const=logging.DEBUG,default=logging.INFO)
    args = parser.parse_args()
    logging.basicConfig(level=args.log_level)
    REGISTRY.register(StatsCollector(args.url))
    logger.info(f"starting server on port {args.port}")
    start_http_server(args.port)
    while True:
        time.sleep(1)
