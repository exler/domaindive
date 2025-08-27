from __future__ import annotations

from typing import Any

from analysis.analyzers._base import AnalysisResult, BaseAnalyzer
from analysis.dependencies import WHOISData


class WHOISAnalyzer(BaseAnalyzer):
    name = "WHOIS"
    dependencies = frozenset({WHOISData})

    def analyze(self, address: str, deps: dict[str, Any]) -> AnalysisResult:
        data = deps.get(WHOISData)
        if not data:
            return AnalysisResult(analyzer_class=type(self), data={"no-whois": "No WHOIS data found"})

        return AnalysisResult(analyzer_class=type(self), data=data)
