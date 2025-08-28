PRD: Listmonk Email Campaign Platform Setup & Integration
Based on the Phase_2_n8n_Workflow_Setup requirements, here's a comprehensive Product Requirements Document for deploying Listmonk as a separate service.

# PRD: NextNest Listmonk Email Campaign Platform

## Project Overview

**Objective:** Deploy Listmonk as a self-hosted email campaign management system to handle bulk email operations for NextNest's mortgage lead nurture workflows.

**Integration Context:** Works with existing n8n workflows to provide scalable campaign management alongside Resend for transactional emails.

## Technical Requirements

### Core Infrastructure
- **Application:** Listmonk v3.0+ (Go binary)
- **Database:** PostgreSQL 13+ with persistent storage
- **SMTP Provider:** Fastmail SMTP for email delivery
- **Domain:** list.nextnest.sg subdomain
- **SSL:** Automatic HTTPS via Railway

### System Resources
- **Memory:** 2GB RAM minimum (campaign processing)
- **CPU:** 1 vCPU (sufficient for 10k+ emails/month)
- **Storage:** 10GB persistent volume for database
- **Network:** Railway's built-in load balancing

## Railway Deployment Configuration

### Repository Setup

```bash
# Create new repository
git clone https://github.com/knadh/listmonk.git nextnest-listmonk
cd nextnest-listmonk

# Add Railway configuration files
touch railway.toml
touch Dockerfile
touch docker-compose.yml
```

### Required Configuration Files

#### railway.toml

```toml
[build]
builder = "dockerfile"

[deploy]
startCommand = "./listmonk --config=config.toml"
healthcheckPath = "/api/health"
healthcheckTimeout = 300
restartPolicyType = "always"

[env]
LISTMONK_app__address = "0.0.0.0:$PORT"
LISTMONK_app__admin_username = "$ADMIN_USERNAME"
LISTMONK_app__admin_password = "$ADMIN_PASSWORD"
```

#### Dockerfile

```dockerfile
FROM listmonk/listmonk:latest

# Copy custom config
COPY config.toml /listmonk/config.toml

# Expose port
EXPOSE $PORT

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:$PORT/api/health || exit 1

# Start command
CMD ["./listmonk", "--config=config.toml"]
```

#### config.toml

```toml
[app]
address = "0.0.0.0:8080"
admin_username = "admin"
admin_password = "changeme123!"
root_url = "https://list.nextnest.sg"

[db]
host = "$DATABASE_HOST"
port = 5432
user = "$DATABASE_USER"
password = "$DATABASE_PASSWORD"
database = "$DATABASE_NAME"
ssl_mode = "require"
max_open = 25
max_idle = 25
max_lifetime = "300s"

[smtp.fastmail]
enabled = true
host = "smtp.fastmail.com"
port = 587
auth_protocol = "login"
username = "$FASTMAIL_USERNAME"
password = "$FASTMAIL_PASSWORD"
hello_hostname = "nextnest.sg"
max_conns = 10
idle_timeout = "15s"
wait_timeout = "5s"
max_msg_retries = 2
tls_enabled = true
tls_skip_verify = false

[privacy]
individual_tracking = true
unsubscribe_header = true
allow_blocklist = true
allow_export = true
allow_wipe = true

[security]
enable_captcha = false
captcha_key = ""
captcha_secret = ""

[upload]
provider = "filesystem"
filesystem.upload_path = "uploads"
filesystem.upload_uri = "/uploads"

[bounce]
enabled = true
webhooks_enabled = false
```

## Environment Variables & Secrets

### Database Configuration
```bash
# Railway PostgreSQL addon provides these automatically
DATABASE_HOST=containers-us-west-xxx.railway.app
DATABASE_USER=postgres
DATABASE_PASSWORD=xxx-generated-password-xxx
DATABASE_NAME=railway
DATABASE_URL=postgresql://postgres:password@host:port/railway
```

### SMTP Configuration
```bash
# Fastmail SMTP credentials
FASTMAIL_USERNAME=campaigns@nextnest.sg
FASTMAIL_PASSWORD=app-specific-password-here
FASTMAIL_SMTP_HOST=smtp.fastmail.com
FASTMAIL_SMTP_PORT=587
```

### Application Secrets
```bash
# Admin access
ADMIN_USERNAME=brent@nextnest.sg
ADMIN_PASSWORD=secure-admin-password-123!

# API access for n8n
LISTMONK_API_KEY=listmonk-api-key-for-n8n-integration
LISTMONK_URL=https://list.nextnest.sg
```

### Domain Configuration
```bash
# Railway custom domain
RAILWAY_STATIC_URL=list.nextnest.sg
LISTMONK_ROOT_URL=https://list.nextnest.sg
```
## n8n Integration Requirements

### API Endpoints for n8n Workflows

#### Subscriber Management

```javascript
// Add subscriber to list
POST https://list.nextnest.sg/api/subscribers
{
  "email": "client@example.com",
  "name": "Client Name",
  "status": "enabled",
  "lists": [1, 2], // List IDs
  "attribs": {
    "lead_score": 85,
    "segment": "Premium",
    "loan_type": "refinance",
    "urgency": "high"
  }
}

// Update subscriber attributes
PUT https://list.nextnest.sg/api/subscribers/123
{
  "attribs": {
    "lead_score": 90,
    "last_engagement": "2024-08-28"
  }
}
```

#### List Management

```javascript
// Create segmented lists
POST https://list.nextnest.sg/api/lists
{
  "name": "premium_refinance",
  "type": "private",
  "description": "Premium leads interested in refinancing"
}

// Predefined lists to create:
// - premium_refinance (score 80-100, loan_type=refinance)
// - qualified_newpurchase (score 60-79, loan_type=purchase)
// - developing_equity (score 40-59, property_type=hdb)
// - cold_leads (score <40, all types)
```

#### Campaign Triggers

```javascript
// Trigger campaign from n8n
POST https://list.nextnest.sg/api/campaigns/123/status
{
  "status": "running"
}

// Campaign types needed:
// - welcome_series (immediate after form)
// - weekly_newsletter (market updates)
// - educational_drip (mortgage tips)
// - rate_alerts (urgent market changes)
// - re_engagement (dormant leads)
```

### n8n Workflow Integration Points

#### Lead Scoring Updates

```javascript
// n8n node: Update Listmonk subscriber
const leadData = {
  email: $json.email,
  lead_score: $json.lead.score,
  segment: $json.lead.segment,
  last_activity: new Date().toISOString()
};

// HTTP Request to Listmonk API
// Method: PUT
// URL: https://list.nextnest.sg/api/subscribers/by-email
// Headers: Authorization: Bearer ${LISTMONK_API_KEY}
```

#### Campaign Routing Logic

```javascript
// n8n switch node logic
if (leadScore >= 80) {
  // Premium: No Listmonk campaigns (Resend only)
  return "premium_resend_only";
} else if (leadScore >= 60) {
  // Qualified: Mixed approach
  return "qualified_mixed_campaigns";
} else {
  // Developing/Cold: Listmonk campaigns
  return "listmonk_nurture_campaigns";
}
```
# Email Templates & Campaigns
Required Email Templates
Welcome Series (3 emails over 7 days)

Day 0: Welcome + Market Overview
Day 3: Educational Content (Mortgage Basics)
Day 7: Success Stories + CTA
Weekly Newsletter Template

Market rate updates
Policy changes
Educational tips
Success stories
Educational Drip Campaign (5 emails over 14 days)

Understanding mortgage types
Government schemes (HDB, EC)
Bank comparison strategies
Timing your application
Documentation checklist
Template Variables
html
<!-- Available in all templates -->
{{.Subscriber.Name}}
{{.Subscriber.Attribs.lead_score}}
{{.Subscriber.Attribs.segment}}
{{.Subscriber.Attribs.loan_type}}
{{.Subscriber.Attribs.urgency}}
{{.Date}}
{{.UnsubscribeURL}}
# Deployment Steps
Phase 1: Repository Setup
Fork Listmonk repository to nextnest-listmonk
Add Railway configuration files
Configure custom config.toml
Set up Dockerfile for Railway deployment
Phase 2: Railway Service Creation
Create new Railway service in NextNest project
Connect to nextnest-listmonk repository
- Add PostgreSQL addon
- Configure environment variables

### Phase 3: Domain & SSL
- Add custom domain: list.nextnest.sg
- Configure DNS CNAME record
- Verify SSL certificate generation
- Test health check endpoint

### Phase 4: SMTP Configuration
- Set up Fastmail app-specific password
- Configure SMTP settings in Listmonk
- Test email delivery
- Set up bounce handling

### Phase 5: Initial Configuration
- Access admin panel at https://list.nextnest.sg
- Create subscriber lists for segmentation
- Import email templates
- Configure campaign settings

### Phase 6: n8n Integration
- Update n8n workflows with Listmonk endpoints
- Test subscriber creation from forms
- Test campaign triggering
- Validate lead scoring updates
## Testing & Validation Checklist

### Infrastructure Tests
- ✅ Railway deployment successful
- ✅ PostgreSQL connection established
- ✅ Custom domain resolves correctly
- ✅ SSL certificate active
- ✅ Health check endpoint responding

### Email Functionality
- ✅ SMTP connection to Fastmail working
- ✅ Test email delivery successful
- ✅ Bounce handling configured
- ✅ Unsubscribe links functional
- ✅ Template rendering correct

### API Integration
- ✅ Subscriber creation via API
- ✅ List management operations
- ✅ Campaign triggering
- ✅ Attribute updates
- ✅ Authentication working

### n8n Workflow Tests
- ✅ Form submission → Listmonk subscriber creation
- ✅ Lead scoring → Attribute updates
- ✅ Campaign routing logic
- ✅ Error handling and fallbacks
- ✅ Performance under load

### Compliance & Security
- ✅ GDPR compliance features enabled
- ✅ Unsubscribe handling
- ✅ Data export functionality
- ✅ Admin access secured
- ✅ API authentication configured
## Success Metrics

### Technical KPIs
- **Uptime:** >99.5%
- **Email delivery rate:** >98%
- **API response time:** <500ms
- **Campaign processing:** 1000 emails/minute

### Business KPIs
- **Email open rates:** >25%
- **Click-through rates:** >3%
- **Unsubscribe rate:** <2%
- **Lead progression:** 15% from developing to qualified

## Maintenance & Monitoring

### Daily Operations
- Monitor email delivery rates
- Check bounce rates and handle blocks
- Review campaign performance
- Update subscriber segments

### Weekly Reviews
- Analyze engagement metrics
- A/B test email templates
- Review and update lists
- Performance optimization

### Monthly Tasks
- Database maintenance
- Security updates
- Backup verification
- Cost optimization review

---

## Project Summary

- **Estimated Timeline:** 3-5 days for full deployment and integration
- **Budget Impact:** ~$15/month (Railway PostgreSQL + compute resources)
- **Risk Level:** Low (proven technology stack with clear rollback path)