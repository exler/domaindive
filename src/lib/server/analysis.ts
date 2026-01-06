import db, { type DomainAnalysis } from "./db.js";
import { fetchDnsRecords, fetchNameservers } from "./dns.js";
import { fetchGeolocation } from "./geolocation.js";
import { fetchHttpHeaders } from "./http.js";
import { fetchSslCertificate } from "./ssl.js";
import { fetchWhois } from "./whois.js";

const CACHE_TTL_MINUTES = 5;

function normalizeAddress(address: string): string {
    return address
        .trim()
        .toLowerCase()
        .replace(/^https?:\/\//, "")
        .replace(/\/$/, "");
}

function needsRefresh(updatedAt: string | null): boolean {
    if (!updatedAt) return true;
    const now = new Date();
    const updated = new Date(updatedAt);
    const ageMinutes = (now.getTime() - updated.getTime()) / 1000 / 60;
    return ageMinutes >= CACHE_TTL_MINUTES;
}

function validateDomain(address: string): boolean {
    const domainRegex = /^[a-zA-Z0-9][a-zA-Z0-9-_.]+\.[a-zA-Z]{2,}$/;
    return domainRegex.test(address);
}

async function performAnalysis(address: string) {
    let whoisData: string | null = null;
    try {
        whoisData = await fetchWhois(address);
    } catch (e) {
        console.error(e);
    }

    const dnsRecords = await fetchDnsRecords(address);
    const nameservers = await fetchNameservers(address);
    const sslInfo = await fetchSslCertificate(address);
    const httpResponse = await fetchHttpHeaders(address);

    let geolocation = {};
    if (dnsRecords.a && dnsRecords.a.length > 0) {
        const ip = dnsRecords.a[0].value;
        geolocation = await fetchGeolocation(ip);
    }

    return {
        address,
        whois_data: whoisData,
        dns_records: JSON.stringify(dnsRecords),
        nameservers: JSON.stringify(nameservers),
        ssl_info: JSON.stringify(sslInfo),
        http_response: JSON.stringify(httpResponse),
        geolocation: JSON.stringify(geolocation),
    };
}

export async function getOrCreateAnalysis(address: string, forceRefresh = false) {
    const normalizedAddress = normalizeAddress(address);

    if (!validateDomain(normalizedAddress)) {
        throw new Error("must be a valid domain name with a top-level domain (e.g., example.com)");
    }

    const query = db.query<DomainAnalysis, string>("SELECT * FROM domain_analyses WHERE address = ?");
    const existing = query.get(normalizedAddress);

    if (existing && !forceRefresh && !needsRefresh(existing.updated_at)) {
        return { analysis: existing, cacheStatus: "cached" as const };
    }

    const analysisData = await performAnalysis(normalizedAddress);

    if (existing) {
        const updateQuery = db.query(`
			UPDATE domain_analyses
			SET whois_data = $whois_data, dns_records = $dns_records, nameservers = $nameservers,
				ssl_info = $ssl_info, http_response = $http_response, geolocation = $geolocation,
				updated_at = CURRENT_TIMESTAMP
			WHERE address = $address
		`);
        updateQuery.run({
            $whois_data: analysisData.whois_data,
            $dns_records: analysisData.dns_records,
            $nameservers: analysisData.nameservers,
            $ssl_info: analysisData.ssl_info,
            $http_response: analysisData.http_response,
            $geolocation: analysisData.geolocation,
            $address: normalizedAddress,
        });
        const updated = query.get(normalizedAddress) as DomainAnalysis;
        return { analysis: updated, cacheStatus: "fresh" as const };
    } else {
        const insertQuery = db.query(`
			INSERT INTO domain_analyses
			(address, whois_data, dns_records, nameservers, ssl_info, http_response, geolocation)
			VALUES ($address, $whois_data, $dns_records, $nameservers, $ssl_info, $http_response, $geolocation)
		`);
        const result = insertQuery.run({
            $address: analysisData.address,
            $whois_data: analysisData.whois_data,
            $dns_records: analysisData.dns_records,
            $nameservers: analysisData.nameservers,
            $ssl_info: analysisData.ssl_info,
            $http_response: analysisData.http_response,
            $geolocation: analysisData.geolocation,
        });
        const getByIdQuery = db.query<DomainAnalysis, bigint>("SELECT * FROM domain_analyses WHERE id = ?");
        const created = getByIdQuery.get(BigInt(result.lastInsertRowid)) as DomainAnalysis;
        return { analysis: created, cacheStatus: "fresh" as const };
    }
}

export function secondsUntilRefresh(updatedAt: string | null): number {
    if (!updatedAt) return 0;
    const now = new Date();
    const updated = new Date(updatedAt);
    const refreshTime = new Date(updated.getTime() + CACHE_TTL_MINUTES * 60 * 1000);
    return Math.max(0, Math.floor((refreshTime.getTime() - now.getTime()) / 1000));
}
