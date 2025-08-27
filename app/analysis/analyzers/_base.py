from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any, Mapping


@dataclass(frozen=True)
class AnalysisResult:
    """Unified unit of information produced by analyzers.

    Keep it simple and serializable for templates or APIs.
    """

    analyzer_class: BaseAnalyzer
    data: Any  # raw value or structure to render (string, list, dict)


class BaseAnalyzer(ABC):
    """Contract for all analyzers.

    - Declare dependencies you need by key names (e.g. "dns_records", "whois").
    - Implement analyze(address, deps) and return a list of AnalysisItem.
    """

    # Human readable name used in outputs
    name: str = "Analyzer"

    # A set of dependency keys this analyzer requires
    dependencies: frozenset[str] = frozenset()

    @abstractmethod
    def analyze(self, address: str, deps: Mapping[str, Any]) -> AnalysisResult:
        """Run analysis using provided dependency data.

        Implementations must not perform network I/O directly; instead,
        they should consume pre-fetched dependency data from `deps`.
        """
        raise NotImplementedError
