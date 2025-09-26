# Sanitize AWS Account IDs

Sanitize all AWS Account IDs, API Gateway URLs, and database connection strings in the technical documentation.

## Setup (One-time)
```bash
# Clone the documentation agents repository
git clone https://github.com/username/claude-documentation-agents.git /tmp/doc-agents
cd /tmp/doc-agents/agents/documentation-updater
./setup-doc-agent.sh
```

## Steps:

1. **Run AWS Sanitization Agent**:
   ```bash
   node .claude/scripts/doc-agent.js --sanitize-aws
   ```

2. **What Gets Sanitized**:
   - **AWS Account IDs**: 12-digit numbers → `<AWS_ACCOUNT_ID>`
   - **API Gateway URLs**: `https://abc123def4.execute-api.us-east-1.amazonaws.com` → `https://<API_GATEWAY_ID>.execute-api.<REGION>.amazonaws.com`
   - **Database URLs**: `postgresql://user:pass@host:5432/db` → `postgresql://<USERNAME>:<PASSWORD>@<HOST>:<PORT>/<DATABASE>`
   - **ARNs**: Replace account IDs with placeholders
   - **ECR URLs**: Replace account IDs with placeholders

3. **Verify Results**: Check that sensitive infrastructure details have been replaced with placeholders

## Alternative: Manual Setup
If you have the agents repository cloned elsewhere:
```bash
# Set the documentation path and run sanitization
export DN_DOCS_PATH="/Users/adriangreen/Documents/DN_Tech_Docs"
node /path/to/agents/documentation-updater/.claude/scripts/doc-agent.js --sanitize-aws
```

## SECURITY BENEFIT:
This command prevents accidental exposure of AWS Account IDs, API Gateway endpoints, and database credentials in technical documentation.