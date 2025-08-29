# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a NextNest deployment of Listmonk, a self-hosted, high-performance email newsletter and mailing list manager. The application is built with Go (backend) and Vue.js (frontend), using PostgreSQL as the database. It's configured for Railway deployment with SMTP integration for email campaigns.

## Common Commands

### Development

```bash
# Run backend in development mode
make run

# Run frontend development server
make run-frontend

# Build the entire application (backend + frontend)
make dist

# Build only frontend assets
make build-frontend

# Run tests
make test
go test ./...

# Docker development environment
make init-dev-docker    # Initialize Docker dev environment with DB
make dev-docker        # Start Docker dev suite
make rm-dev-docker     # Tear down Docker dev environment
```

### Build & Deployment

```bash
# Build production binary with embedded assets
make dist

# Create release builds
make release-dry       # Dry run of release process
make release          # Build and publish production releases

# Manual binary operations
./listmonk --new-config    # Generate config.toml
./listmonk --install       # Setup PostgreSQL database
./listmonk --upgrade       # Upgrade existing database
./listmonk                 # Run the application
```

### Frontend Development

```bash
cd frontend
yarn install          # Install dependencies
yarn dev             # Run development server
yarn build           # Build production assets
yarn lint            # Run ESLint
```

## Architecture Overview

### Backend Structure (Go)

The Go backend follows a modular architecture:

- **cmd/**: Main application entry points and HTTP handlers
  - `main.go`: Application bootstrap and configuration
  - `handlers.go`: Core HTTP route handlers
  - `campaigns.go`, `subscribers.go`, `lists.go`: Domain-specific handlers
  - `auth.go`: Authentication and authorization logic
  - `init.go`: Initialization and dependency injection

- **internal/**: Core business logic (not exposed externally)
  - `core/`: Domain models and business logic
  - `manager/`: Campaign processing and email queue management
  - `messenger/`: Email delivery implementations
  - `bounce/`: Bounce handling (webhooks and mailbox monitoring)
  - `media/`: File storage providers (filesystem, S3)
  - `auth/`: Authentication providers (OIDC, built-in)
  - `migrations/`: Database migration files

- **models/**: Data models and database queries
  - Uses SQLX for database operations
  - SQL queries defined in `queries.sql`

### Frontend Structure (Vue.js)

The Vue.js frontend uses Buefy (Bulma-based UI components):

- **frontend/src/views/**: Main application views
  - Campaign management, subscriber management, templates, settings
  - Uses Vue Router for navigation

- **frontend/src/components/**: Reusable Vue components
  - Editor components (TinyMCE, CodeMirror, Visual Builder)
  - Charts, navigation, list selectors

- **frontend/email-builder/**: Visual email template builder
  - Separate TypeScript/React application
  - Builds to static assets included in main frontend

### Key Integration Points

1. **API Structure**: RESTful API at `/api/*` endpoints
   - Authentication via session cookies or API tokens
   - JSON request/response format

2. **Campaign Processing**: 
   - Managed by internal `manager` package
   - Uses worker pools for concurrent email sending
   - Supports multiple SMTP configurations

3. **Template System**:
   - Go text/template for email rendering
   - Supports custom variables and logic
   - Visual builder exports JSON format

4. **Database Schema**:
   - PostgreSQL with JSONB for flexible subscriber attributes
   - Efficient indexing for large-scale operations
   - Migration system for schema updates

## Railway Deployment Configuration

The application is configured for Railway deployment with:

- **railway.toml**: Deployment configuration using Dockerfile
- **Environment variables** for database and SMTP configuration
- **Health check** endpoint at `/api/health`
- **PostgreSQL addon** for database

Key environment variables:
- `LISTMONK_app__address`: Bind address (uses Railway's $PORT)
- `LISTMONK_app__admin_username/password`: Admin credentials
- Database connection via Railway's PostgreSQL addon variables

## Development Notes

- The application uses `stuffbin` to embed static assets into the binary for production builds
- Frontend assets are built with Vite and embedded at compile time
- Database migrations are idempotent and can be run multiple times safely
- The application supports horizontal scaling for campaign processing
- Email templates use Go's text/template syntax with Sprig functions