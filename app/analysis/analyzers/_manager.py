from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Iterable

from analysis.analyzers._base import AnalysisResult, BaseAnalyzer
from analysis.dependencies import BaseAnalyzerDependency


@dataclass(frozen=True)
class AnalysisReport:
    address: str
    items: list[AnalysisResult]
    errors: dict[BaseAnalyzerDependency, BaseException]


class AnalyzerManager:
    """Coordinates analyzers and shared dependency fetching.

    Usage:
        mgr = AnalyzerManager([DNSRecordsAnalyzer(), WHOISAnalyzer()])
        report = mgr.run("example.com")
    """

    def __init__(self, analyzers: Iterable[BaseAnalyzer]):
        self._analyzers = list(analyzers)

    def _collect_required_dependencies(self) -> set[str]:
        keys: set[str] = set()
        for a in self._analyzers:
            keys.update(a.dependencies)
        return keys

    def _fetch_dependencies(
        self, address: str, dependencies: Iterable[BaseAnalyzerDependency]
    ) -> tuple[dict[BaseAnalyzerDependency, Any], dict[BaseAnalyzerDependency, BaseException]]:
        data: dict[BaseAnalyzerDependency, Any] = {}
        errors: dict[BaseAnalyzerDependency, BaseException] = {}
        for dep_class in dependencies:
            dep = dep_class()
            try:
                data[dep_class] = dep.fetch(address)
            except Exception as e:
                errors[dep_class] = e
        return data, errors

    def run(self, address: str) -> AnalysisReport:
        dep_classes = self._collect_required_dependencies()
        dep_data, dep_errors = self._fetch_dependencies(address, dep_classes)

        items: list[AnalysisResult] = []
        for analyzer in self._analyzers:
            try:
                result = analyzer.analyze(address, dep_data)
                items.append(result)
            except Exception as e:
                # Represent analyzer error as an item for visibility
                items.append(AnalysisResult(analyzer_class=type(analyzer), data=str(e)))

        return AnalysisReport(address=address, items=items, errors=dep_errors)
