# AGENTS.md DomainDive

DomainDive is a TypeScript-based web application built with SvelteKit that provides a comprehensive view of a domain's DNS, WHOIS, HTTP, and security details.

## Technology Stack

- **SvelteKit**: Web framework
- **TypeScript**
- **Tailwind CSS**
- **Bun SQLite**: Embedded SQL database for caching

## Project Structure

```
src/
├── lib/
│   └── server/
│       ├── analysis.ts    # Main analysis orchestrator
│       ├── db.ts          # Database setup and types
│       ├── dns.ts         # DNS lookup service
│       ├── whois.ts       # WHOIS service
│       ├── ssl.ts         # SSL certificate checker
│       ├── http.ts        # HTTP headers fetcher
│       └── geolocation.ts # IP geolocation service
└── routes/
    ├── +page.svelte       # Home page
    └── analysis/
        ├── +page.svelte        # Analysis results page
        └── +page.server.ts     # Server-side data loader
```

## Dev environment

* Use `bun` for frontend package management and tasks.
