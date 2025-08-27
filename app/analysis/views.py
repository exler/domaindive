from django.shortcuts import render
from django.views.generic import FormView

from analysis.analyzers._manager import AnalyzerManager
from analysis.analyzers.dns import DNSRecordsAnalyzer
from analysis.analyzers.whois import WHOISAnalyzer
from analysis.forms import RequestAnalysisForm


class RequestAnalysisView(FormView):
    template_name = "analysis/request_analysis.html"
    form_class = RequestAnalysisForm

    def form_valid(self, form):
        address: str = form.cleaned_data["address"]

        mgr = AnalyzerManager(
            [
                DNSRecordsAnalyzer(),
                WHOISAnalyzer(),
            ]
        )
        report = mgr.run(address)

        return render(
            self.request,
            "analysis/analysis_dashboard.html",
            {"report": report},
        )
