import { connect } from 'node:tls';
import { Resolver } from 'node:dns/promises';

const resolver = new Resolver();

export interface SslInfo {
	available: boolean;
	subject?: string;
	issuer?: string;
	valid_from?: string;
	valid_to?: string;
	san?: string[];
}

export async function fetchSslCertificate(domain: string): Promise<SslInfo> {
	try {
		const addresses = await resolver.resolve4(domain);
		if (addresses.length === 0) {
			return { available: false };
		}

		const ip = addresses[0];
		
		return new Promise((resolve) => {
			const socket = connect({
				host: ip,
				port: 443,
				servername: domain,
				rejectUnauthorized: false,
				timeout: 10000
			}, () => {
				const cert = socket.getPeerCertificate();
				socket.end();

				if (!cert || Object.keys(cert).length === 0) {
					resolve({ available: false });
					return;
				}

				resolve({
					available: true,
					subject: cert.subject?.CN || 'Unknown',
					issuer: cert.issuer?.CN || 'Unknown',
					valid_from: cert.valid_from || undefined,
					valid_to: cert.valid_to || undefined,
					san: cert.subjectaltname 
						? cert.subjectaltname.split(', ').map((s: string) => s.replace('DNS:', ''))
						: []
				});
			});

			socket.on('error', () => {
				resolve({ available: false });
			});

			socket.on('timeout', () => {
				socket.destroy();
				resolve({ available: false });
			});
		});
	} catch (e) {
		return { available: false };
	}
}
