import { createConnection } from 'node:net';

const WHOIS_SERVER = 'whois.internic.net';
const WHOIS_PORT = 43;
const TIMEOUT = 10000;

export interface WhoisInfo {
	registrar: string | null;
	created_date: string | null;
	expiry_date: string | null;
	updated_date: string | null;
	status: string | null;
	name_servers: string[];
}

export async function fetchWhois(domain: string): Promise<string> {
	return new Promise((resolve, reject) => {
		const socket = createConnection({ host: WHOIS_SERVER, port: WHOIS_PORT });
		let data = '';

		const timer = setTimeout(() => {
			socket.destroy();
			reject(new Error('Timeout'));
		}, TIMEOUT);

		socket.on('connect', () => {
			socket.write(`${domain}\r\n`);
		});

		socket.on('data', (chunk) => {
			data += chunk.toString();
		});

		socket.on('end', () => {
			clearTimeout(timer);
			resolve(data);
		});

		socket.on('error', (err) => {
			clearTimeout(timer);
			reject(err);
		});
	});
}

export function parseWhois(whoisData: string | null): WhoisInfo {
	if (!whoisData) return {
		registrar: null,
		created_date: null,
		expiry_date: null,
		updated_date: null,
		status: null,
		name_servers: []
	};

	const extractField = (fieldNames: string[]): string | null => {
		for (const fieldName of fieldNames) {
			const regex = new RegExp(`${fieldName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\s*(.+)`, 'i');
			const match = whoisData.match(regex);
			if (match) return match[1].trim();
		}
		return null;
	};

	const extractStatus = (): string | null => {
		const matches = [...whoisData.matchAll(/Domain Status:\s*(.+)/gi)];
		if (matches.length === 0) return null;
		return matches.map(m => m[1].trim()).join(', ');
	};

	const extractNameServers = (): string[] => {
		const matches = [...whoisData.matchAll(/Name Server:\s*(.+)/gi)];
		return [...new Set(matches.map(m => m[1].trim().toLowerCase()))];
	};

	return {
		registrar: extractField(['Registrar:', 'Registrar Name:']),
		created_date: extractField(['Creation Date:', 'Created Date:']),
		expiry_date: extractField(['Registry Expiry Date:', 'Expiration Date:', 'Expiry Date:']),
		updated_date: extractField(['Updated Date:', 'Last Updated:']),
		status: extractStatus(),
		name_servers: extractNameServers()
	};
}
