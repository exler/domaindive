<script lang="ts">
    import type { DnsRecord, DnsRecords } from "$lib/server/dns";
    import type { PageData } from "./$types";

    const { data }: { data: PageData } = $props();

    function formatDate(dateString: string | null | undefined): string {
        if (!dateString) return "N/A";
        return dateString.split("T")[0];
    }

    function formatUpdatedAt(updatedAt: string): string {
        const date = new Date(updatedAt);
        const year = date.getUTCFullYear();
        const month = String(date.getUTCMonth() + 1).padStart(2, "0");
        const day = String(date.getUTCDate()).padStart(2, "0");
        const hours = String(date.getUTCHours()).padStart(2, "0");
        const minutes = String(date.getUTCMinutes()).padStart(2, "0");
        return `${year}-${month}-${day} ${hours}:${minutes} UTC`;
    }

    function flattenDnsRecords(records: DnsRecords) {
        if (!records) return [];

        const flattened: (DnsRecord & { type: string })[] = [];
        for (const [type, recordList] of Object.entries(records)) {
            if (Array.isArray(recordList)) {
                for (const record of recordList) {
                    flattened.push({ ...record, type: type.toUpperCase() });
                }
            }
        }
        return flattened;
    }

    let flatDnsRecords = $derived(flattenDnsRecords(data.dnsRecords));
</script>

<svelte:head>
    <title>{data.domain} | DomainDive</title>
</svelte:head>

<main class="max-w-2xl mx-auto px-6 py-16">
    <div class="mb-10">
        <a href="/" class="inline-flex items-center text-sm text-sky-700 hover:text-sky-900 transition-colors mb-6">
            <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
            New analysis
        </a>
        <div class="flex items-start justify-between mb-4">
            <div>
                <h1 class="text-3xl font-light text-slate-800 tracking-tight mb-1">
                    {data.domain}
                </h1>
                <p class="text-sm text-slate-500">
                    Last updated {formatUpdatedAt(data.updatedAt)}
                </p>
            </div>
            <a
                href="/analysis?domain={encodeURIComponent(data.domain)}&refresh=true"
                class="text-sm text-sky-700 hover:text-sky-900 flex items-center gap-1 transition-colors"
            >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
                    />
                </svg>
                Refresh
            </a>
        </div>
    </div>

    <!-- WHOIS Information -->
    <div class="mb-8 bg-white/60 backdrop-blur rounded-lg p-6">
        <div class="flex items-center gap-2 mb-4">
            <svg class="w-5 h-5 text-sky-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
            </svg>
            <h2 class="text-lg font-medium text-slate-800">WHOIS Information</h2>
        </div>

        {#if data.whoisInfo && Object.keys(data.whoisInfo).length > 0}
            <div class="space-y-0 border-l-2 border-sky-300">
                <div class="flex items-center py-3 pl-6">
                    <span class="text-sm text-slate-500 w-40">Registrar</span>
                    <span class="text-sm text-slate-800 font-medium">
                        {data.whoisInfo.registrar || "Unknown"}
                    </span>
                </div>

                <div class="flex items-center py-3 pl-6">
                    <span class="text-sm text-slate-500 w-40">Creation Date</span>
                    <span class="text-sm text-slate-800 font-medium">
                        {formatDate(data.whoisInfo.created_date)}
                    </span>
                </div>

                <div class="flex items-center py-3 pl-6">
                    <span class="text-sm text-slate-500 w-40">Expiration Date</span>
                    <span class="text-sm text-slate-800 font-medium">
                        {formatDate(data.whoisInfo.expiry_date)}
                    </span>
                </div>
            </div>
        {:else}
            <div class="text-sm text-slate-500 pl-6">WHOIS data unavailable</div>
        {/if}
    </div>

    <!-- Server Location -->
    <div class="mb-8 bg-white/60 backdrop-blur rounded-lg p-6">
        <div class="flex items-center gap-2 mb-4">
            <svg class="w-5 h-5 text-sky-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                />
                <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                />
            </svg>
            <h2 class="text-lg font-medium text-slate-800">Server Location</h2>
        </div>

        {#if data.geolocation && Object.keys(data.geolocation).length > 0}
            <div class="space-y-0 border-l-2 border-sky-300">
                {#if data.geolocation.country}
                    <div class="flex items-center py-3 pl-6">
                        <span class="text-sm text-slate-500 w-40">Country</span>
                        <span class="text-sm text-slate-800 font-medium">{data.geolocation.country}</span>
                    </div>
                {/if}
                {#if data.geolocation.region}
                    <div class="flex items-center py-3 pl-6">
                        <span class="text-sm text-slate-500 w-40">Region</span>
                        <span class="text-sm text-slate-800 font-medium">{data.geolocation.region}</span>
                    </div>
                {/if}
                {#if data.geolocation.city}
                    <div class="flex items-center py-3 pl-6">
                        <span class="text-sm text-slate-500 w-40">City</span>
                        <span class="text-sm text-slate-800 font-medium">{data.geolocation.city}</span>
                    </div>
                {/if}
                {#if data.geolocation.lat && data.geolocation.lon}
                    <div class="flex items-center py-3 pl-6">
                        <span class="text-sm text-slate-500 w-40">Coordinates</span>
                        <span class="text-sm text-slate-800 font-medium">
                            {data.geolocation.lat}, {data.geolocation.lon}
                        </span>
                    </div>
                {/if}
                {#if data.geolocation.isp}
                    <div class="flex items-center py-3 pl-6">
                        <span class="text-sm text-slate-500 w-40">ISP</span>
                        <span class="text-sm text-slate-800 font-medium">{data.geolocation.isp}</span>
                    </div>
                {/if}
            </div>
        {:else}
            <div class="text-sm text-slate-500 pl-6">Geolocation data unavailable</div>
        {/if}
    </div>

    <!-- Nameservers -->
    <div class="mb-8 bg-white/60 backdrop-blur rounded-lg p-6">
        <div class="flex items-center gap-2 mb-4">
            <svg class="w-5 h-5 text-sky-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-2-4h.01M17 16h.01"
                />
            </svg>
            <h2 class="text-lg font-medium text-slate-800">DNS Nameservers</h2>
        </div>

        {#if data.nameservers && data.nameservers.length > 0}
            <div class="space-y-0 border-l-2 border-sky-300">
                {#each data.nameservers as ns}
                    <div class="py-3 pl-6">
                        <div class="text-sm text-slate-800 font-medium">{ns.hostname}</div>
                        {#if ns.ip_address}
                            <div class="text-xs text-slate-500">{ns.ip_address}</div>
                        {/if}
                    </div>
                {/each}
            </div>
        {:else}
            <div class="text-sm text-slate-500 pl-6">No DNS servers found</div>
        {/if}
    </div>

    <!-- DNS Records -->
    <div class="mb-8 bg-white/60 backdrop-blur rounded-lg p-6">
        <div class="flex items-center gap-2 mb-4">
            <svg class="w-5 h-5 text-sky-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                />
            </svg>
            <h2 class="text-lg font-medium text-slate-800">DNS Records</h2>
        </div>

        {#if flatDnsRecords.length > 0}
            <div class="space-y-0 border-l-2 border-sky-300">
                {#each flatDnsRecords as record}
                    <div class="py-3 pl-6">
                        <div class="text-sm text-slate-800 font-medium">{record.value}</div>
                        <div class="text-xs text-slate-500">{record.type}</div>
                    </div>
                {/each}
            </div>
        {:else}
            <div class="text-sm text-slate-500 pl-6">No DNS records found</div>
        {/if}
    </div>

    <!-- HTTP Response -->
    <div class="mb-8 bg-white/60 backdrop-blur rounded-lg p-6">
        <div class="flex items-center gap-2 mb-4">
            <svg class="w-5 h-5 text-sky-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"
                />
            </svg>
            <h2 class="text-lg font-medium text-slate-800">HTTP Response</h2>
        </div>

        {#if data.httpResponse && data.httpResponse.status}
            <div class="space-y-0 border-l-2 border-sky-300">
                <div class="flex items-center py-3 pl-6">
                    <span class="text-sm text-slate-500 w-40">status</span>
                    <span
                        class="text-sm font-medium {data.httpResponse.status >= 200 && data.httpResponse.status < 300
                            ? 'text-emerald-600'
                            : 'text-slate-800'}"
                    >
                        {data.httpResponse.status}
                    </span>
                </div>

                {#if data.httpResponse.headers}
                    {#each Object.entries(data.httpResponse.headers) as [key, value]}
                        <div class="flex items-center py-3 pl-6">
                            <span class="text-sm text-slate-500 w-40 truncate" title={key}>{key}</span>
                            <span class="text-sm text-slate-800 font-medium break-all">{value}</span>
                        </div>
                    {/each}
                {/if}
            </div>
        {:else}
            <div class="text-sm text-slate-500 pl-6">No response data available</div>
        {/if}
    </div>

    <!-- SSL Certificate -->
    <div class="mb-8 bg-white/60 backdrop-blur rounded-lg p-6">
        <div class="flex items-center gap-2 mb-4">
            <svg class="w-5 h-5 text-sky-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                />
            </svg>
            <h2 class="text-lg font-medium text-slate-800">SSL Certificate</h2>
        </div>

        {#if data.sslInfo && data.sslInfo.available}
            <div class="space-y-0 border-l-2 border-sky-300">
                {#if data.sslInfo.subject}
                    <div class="flex items-center py-3 pl-6">
                        <span class="text-sm text-slate-500 w-40">Subject</span>
                        <span class="text-sm text-slate-800 font-medium">{data.sslInfo.subject}</span>
                    </div>
                {/if}
                {#if data.sslInfo.issuer}
                    <div class="flex items-center py-3 pl-6">
                        <span class="text-sm text-slate-500 w-40">Issuer</span>
                        <span class="text-sm text-slate-800 font-medium">{data.sslInfo.issuer}</span>
                    </div>
                {/if}
                {#if data.sslInfo.valid_from}
                    <div class="flex items-center py-3 pl-6">
                        <span class="text-sm text-slate-500 w-40">Valid From</span>
                        <span class="text-sm text-slate-800 font-medium">{data.sslInfo.valid_from}</span>
                    </div>
                {/if}
                {#if data.sslInfo.valid_to}
                    <div class="flex items-center py-3 pl-6">
                        <span class="text-sm text-slate-500 w-40">Valid To</span>
                        <span class="text-sm text-slate-800 font-medium">{data.sslInfo.valid_to}</span>
                    </div>
                {/if}
            </div>
        {:else}
            <div class="text-sm text-slate-500 pl-6">SSL certificate unavailable</div>
        {/if}
    </div>

    <img src="/images/logo.png" alt="DomainDive Logo" class="w-32 h-32 mx-auto" />
</main>
