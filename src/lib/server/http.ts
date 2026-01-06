export interface HttpResponse {
    status?: number;
    headers?: Record<string, string>;
}

export async function fetchHttpHeaders(domain: string): Promise<HttpResponse> {
    const tryFetch = async (url: string): Promise<HttpResponse | null> => {
        try {
            const response = await fetch(url, {
                method: "HEAD",
                redirect: "manual",
                signal: AbortSignal.timeout(10000),
            });

            if (response.status >= 200 && response.status < 400) {
                const headers: Record<string, string> = {};
                response.headers.forEach((value, key) => {
                    headers[key] = value;
                });
                return { status: response.status, headers };
            }
            return null;
        } catch (e) {
            console.error(e);
            return null;
        }
    };

    let result = await tryFetch(`https://${domain}`);
    if (!result) {
        result = await tryFetch(`http://${domain}`);
    }

    return result || {};
}
