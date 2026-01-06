import { Resolver } from "node:dns/promises";

const resolver = new Resolver();

export interface DnsRecord {
    value: string;
    ttl: number;
    priority?: number;
}

export interface DnsRecords {
    a: DnsRecord[];
    aaaa: DnsRecord[];
    mx: DnsRecord[];
    txt: DnsRecord[];
    cname: DnsRecord[];
}

export interface Nameserver {
    hostname: string;
    ip_address: string | null;
}

export async function fetchDnsRecords(domain: string): Promise<DnsRecords> {
    const results: DnsRecords = {
        a: [],
        aaaa: [],
        mx: [],
        txt: [],
        cname: [],
    };

    try {
        const addresses = await resolver.resolve4(domain, { ttl: true });
        results.a = addresses.map(({ address, ttl }) => ({ value: address, ttl }));
    } catch (e) {
        console.error(e);
    }

    try {
        const addresses = await resolver.resolve6(domain, { ttl: true });
        results.aaaa = addresses.map(({ address, ttl }) => ({ value: address, ttl }));
    } catch (e) {
        console.error(e);
    }

    try {
        const exchanges = await resolver.resolveMx(domain);
        results.mx = exchanges.map(({ exchange, priority }) => ({ value: exchange, priority, ttl: 0 }));
    } catch (e) {
        console.error(e);
    }

    try {
        const records = await resolver.resolveTxt(domain);
        results.txt = records.map((record) => ({ value: record.join(""), ttl: 0 }));
    } catch (e) {
        console.error(e);
    }

    try {
        const cname = await resolver.resolveCname(domain);
        results.cname = cname.map((value) => ({ value, ttl: 0 }));
    } catch (e) {
        console.error(e);
    }

    return results;
}

export async function fetchNameservers(domain: string): Promise<Nameserver[]> {
    try {
        const nameservers = await resolver.resolveNs(domain);

        const nameserversWithIps = await Promise.all(
            nameservers.map(async (hostname): Promise<Nameserver> => {
                let ip_address: string | null = null;
                try {
                    const addresses = await resolver.resolve4(hostname);
                    if (addresses.length > 0) {
                        ip_address = addresses[0];
                    }
                } catch (e) {
                    console.error(e);
                }
                return { hostname, ip_address };
            }),
        );

        return nameserversWithIps;
    } catch (e) {
        console.error(e);
        return [];
    }
}
