import { Database } from "bun:sqlite";

const db = new Database("domaindive.db");

db.run(`
	CREATE TABLE IF NOT EXISTS domain_analyses (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		address TEXT NOT NULL UNIQUE,
		whois_data TEXT,
		dns_records JSON,
		nameservers JSON,
		ssl_info JSON,
		http_response JSON,
		geolocation JSON,
		created_at TEXT DEFAULT CURRENT_TIMESTAMP,
		updated_at TEXT DEFAULT CURRENT_TIMESTAMP
	)
`);

export interface DomainAnalysis {
    id: bigint;
    address: string;
    whois_data: string | null;
    dns_records: string;
    nameservers: string;
    ssl_info: string;
    http_response: string;
    geolocation: string;
    created_at: string;
    updated_at: string;
}

export default db;
