# Documentation Security Audit

Perform a comprehensive security audit of the technical documentation to detect exposed secrets, API keys, credentials, and security vulnerabilities.

## Usage:

### Setup (One-time)
```bash
# Clone the agents repository
git clone https://github.com/username/claude-documentation-agents.git /tmp/doc-agents
cd /tmp/doc-agents/agents/security-auditor
./setup-documentation-security-agent.sh
```

### Run Security Scan
```bash
node .claude/scripts/security-scanner.js
```

### Export Reports
```bash
# Markdown report (recommended)
node .claude/scripts/security-scanner.js --export --md

# JSON format
node .claude/scripts/security-scanner.js --export --json

# CSV format for spreadsheet analysis
node .claude/scripts/security-scanner.js --export --csv
```

## Detection Capabilities:

### 🔴 Critical Issues
- **AWS Credentials**: Access keys, secret keys, account IDs
- **Database URLs**: PostgreSQL, MongoDB, MySQL with credentials
- **GitHub Tokens**: Personal access tokens  
- **Stripe Keys**: Live payment processing keys
- **Private Keys**: RSA, EC, SSH private keys

### 🟠 High Risk Issues
- **API Keys**: Google, YouTube, Flask secrets, JWT tokens
- **SSH Keys**: Public key exposures
- **Environment Secrets**: Password/secret patterns

### 🟡 Medium Risk Issues
- **API Gateway URLs**: AWS API Gateway endpoints
- **Admin Panels**: Dashboard and management URLs
- **Debug Endpoints**: Development and test URLs
- **Private IPs**: Internal network addresses

## Smart Features:
- **False Positive Reduction**: Ignores examples, placeholders, and demo content
- **Context Awareness**: Understands code blocks and documentation patterns
- **Severity Scoring**: Prioritizes critical security issues
- **Remediation Guidance**: Specific fix recommendations for each finding

## Report Format:
- Executive summary with severity breakdown
- File-by-file vulnerability listings
- Line-by-line code references
- Actionable remediation steps

The scanner automatically focuses on genuine security risks while filtering out documentation examples.