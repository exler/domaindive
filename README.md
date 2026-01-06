<p align="center">
    <img src="static/images/logo.png" width="180">
    <h3 align="center">DomainDive</h3>
    <p align="center">🤿 Dive deep into any domain or IP to uncover DNS, WHOIS, HTTP, and security details </p>
</p>

DomainDive is a TypeScript-based web application built with SvelteKit that provides a comprehensive view of a domain's DNS, WHOIS, HTTP, and security details.

## Features

- **WHOIS Lookup**: Retrieve domain registration information
- **DNS Records**: View A, AAAA, MX, TXT, CNAME records
- **SSL Certificate**: Check SSL/TLS certificate details
- **HTTP Headers**: Analyze HTTP response headers
- **Geolocation**: Discover server location based on IP
- **Caching**: Results are cached for 5 minutes to improve performance

## Usage

### Development

1. Install dependencies:
   ```bash
   bun install
   ```

2. Run the development server:
   ```bash
   bun --bun run dev
   ```

3. Access the application at `http://localhost:5173`.

### Production

1. Build the application:
   ```bash
   bun --bun run build
   ```

2. Run the production server:
   ```bash
   bun run build/index.js
   ```

### Docker

To run DomainDive using Docker:

1. Build and run the Docker container:
   ```bash
   docker-compose up -d
   ```

2. Access the application at `http://localhost:3000`.
