import { error } from "@sveltejs/kit";
import { getOrCreateAnalysis, secondsUntilRefresh } from "$lib/server/analysis.js";
import type { DnsRecords, Nameserver } from "$lib/server/dns";
import type { GeolocationInfo } from "$lib/server/geolocation";
import type { HttpResponse } from "$lib/server/http";
import type { SslInfo } from "$lib/server/ssl";
import { parseWhois } from "$lib/server/whois.js";
import type { PageServerLoad } from "./$types";

export const load: PageServerLoad = async ({ url }) => {
    const domain = url.searchParams.get("domain");
    const refresh = url.searchParams.get("refresh") === "true";

    if (!domain) {
        error(400, "Domain parameter is required");
    }

    try {
        const { analysis, cacheStatus } = await getOrCreateAnalysis(domain, refresh);

        const whoisInfo = parseWhois(analysis.whois_data);
        const dnsRecords = JSON.parse(analysis.dns_records) as DnsRecords;
        const nameservers = JSON.parse(analysis.nameservers) as Nameserver[];
        const sslInfo = JSON.parse(analysis.ssl_info) as SslInfo;
        const httpResponse = JSON.parse(analysis.http_response) as HttpResponse;
        const geolocation = JSON.parse(analysis.geolocation) as GeolocationInfo;

        const secondsUntil = secondsUntilRefresh(analysis.updated_at);

        return {
            domain: analysis.address,
            updatedAt: analysis.updated_at,
            cacheStatus,
            secondsUntilRefresh: secondsUntil,
            whoisInfo,
            dnsRecords,
            nameservers,
            sslInfo,
            httpResponse,
            geolocation,
        };
    } catch (e) {
        const message = e instanceof Error ? e.message : "Invalid domain name";
        error(400, message);
    }
};
