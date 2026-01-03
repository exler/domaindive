<p align="center">
    <img src="priv/static/images/logo.png" width="180">
    <h3 align="center">DomainDive</h3>
    <p align="center">Dive deep into any domain or IP to uncover DNS, WHOIS, HTTP, and security details </p>
</p>

DomainDive is an Elixir-based web application that provides a comprehensive view of a domain's DNS, WHOIS, HTTP, and security details.

## Usage

### Docker

To run DomainDive using Docker, follow these steps:
1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Fill in the required environment variables in the `.env` file.
3. Build and run the Docker container:
   ```bash
   docker-compose up --d
   ```

4. Access the application at `http://localhost:4000`.
