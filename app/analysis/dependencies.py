from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any, Dict

import dns.resolver
import whois


@dataclass(frozen=True)
class DNSRecord:
    rtype: str
    values: list[str]


class BaseAnalyzerDependency(ABC):
    """Abstract dependency that can fetch once and be shared across analyzers."""

    @abstractmethod
    def fetch(self, address: str) -> Any:
        raise NotImplementedError


class DNSRecords(BaseAnalyzerDependency):
    def fetch(self, address: str) -> Dict[str, DNSRecord]:
        domain = address.rstrip(".")
        types = (
            "A",
            "AAAA",
            "CNAME",
            "NS",
            "MX",
            "TXT",
            "SOA",
            "CAA",
            "SRV",
            "TLSA",
            "DNSKEY",
            "DS",
            "NAPTR",
        )

        res = dns.resolver.Resolver(configure=True)
        res.lifetime = 3.0
        out: Dict[str, DNSRecord] = {}
        for t in types:
            try:
                ans = res.resolve(domain, t, raise_on_no_answer=False)
                if ans.rrset:
                    values = [r.to_text() for r in ans]
                    out[t] = DNSRecord(t, values)
            except (dns.resolver.NXDOMAIN, dns.resolver.NoAnswer):
                continue
            except (dns.resolver.Timeout, Exception):
                continue
        return out


class WHOISData(BaseAnalyzerDependency):
    def fetch(self, address: str) -> Any:
        return whois.whois(address)
