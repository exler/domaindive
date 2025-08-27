from typing import Any

from analysis.analyzers._base import AnalysisResult, BaseAnalyzer
from analysis.dependencies import DNSRecord, DNSRecords


class DNSRecordsAnalyzer(BaseAnalyzer):
    name = "DNS Records"
    dependencies = frozenset({DNSRecords})

    def analyze(self, address: str, deps: dict[str, Any]) -> AnalysisResult:
        data: dict[str, DNSRecord] = deps.get(DNSRecords, {})  # type: ignore[assignment]
        if not data:
            return AnalysisResult(analyzer_class=type(self), data={"no-records": "No DNS records found"})

        return AnalysisResult(analyzer_class=type(self), data=data)
