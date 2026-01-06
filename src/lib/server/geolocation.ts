const API_URL = "http://ip-api.com/json/";

export interface GeolocationInfo {
    ip?: string;
    country?: string;
    region?: string;
    city?: string;
    zip?: string;
    lat?: number;
    lon?: number;
    timezone?: string;
    isp?: string;
    org?: string;
    as?: string;
}

export async function fetchGeolocation(ipAddress: string): Promise<GeolocationInfo> {
    try {
        const response = await fetch(`${API_URL}${ipAddress}`, {
            signal: AbortSignal.timeout(10000),
        });

        if (!response.ok) {
            return {};
        }

        const data = await response.json();

        if (data.status === "success") {
            return {
                ip: data.query,
                country: data.country,
                region: data.regionName,
                city: data.city,
                zip: data.zip,
                lat: data.lat,
                lon: data.lon,
                timezone: data.timezone,
                isp: data.isp,
                org: data.org,
                as: data.as,
            };
        }

        return {};
    } catch (e) {
        console.error(e);
        return {};
    }
}
