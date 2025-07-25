# Infrastructure as Code Backup and Deployment Procedures

## Overview
This document provides comprehensive backup and deployment procedures for Infrastructure as Code (IaC) templates, configurations, and automated deployment pipelines used in Distro Nation's AWS and Firebase infrastructure. This ensures rapid infrastructure recovery and maintains deployment consistency across environments.

## Executive Summary

### Infrastructure as Code Inventory
```yaml
IaC Technologies in Use:
  - AWS CloudFormation: Primary infrastructure provisioning
  - AWS CDK: Higher-level infrastructure abstraction
  - Terraform: Alternative infrastructure management
  - Firebase CLI: Firebase resource configuration
  - AWS SAM: Serverless application model
  - GitHub Actions: CI/CD pipeline automation

Current Deployment Pattern:
  - Source Control: Git repositories
  - CI/CD: GitHub Actions workflows
  - Infrastructure: CloudFormation stacks
  - Serverless: SAM/CDK deployment
```

### Backup Strategy Overview
- **Source Code**: Git version control with multiple remote repositories
- **CloudFormation Templates**: Automated template backup and state management
- **CDK Applications**: Source code backup with synthesized template archives
- **Deployment Pipelines**: Workflow configuration backup and secrets management
- **Infrastructure State**: Stack drift detection and state reconciliation

## 1. Source Code Repository Backup

### 1.1 Git Repository Backup Strategy

#### Multi-Remote Repository Configuration
```bash
#!/bin/bash
# setup-git-backup-remotes.sh
# Configure multiple Git remotes for redundancy

REPO_DIR="."
PRIMARY_REMOTE="origin"
BACKUP_REMOTES=("github-backup" "aws-codecommit" "gitlab-backup")

echo "Setting up backup remotes for repository backup strategy..."

# Add backup remotes
git remote add github-backup https://github.com/backup-org/distro-nation-infrastructure.git
git remote add aws-codecommit https://git-codecommit.<REGION>.amazonaws.com/v1/repos/distro-nation-infra
git remote add gitlab-backup https://gitlab.com/backup-org/distro-nation-infra.git

# Configure push to all remotes
git remote set-url --add --push origin https://github.com/distro-nation/infrastructure.git
git remote set-url --add --push origin https://github.com/backup-org/distro-nation-infrastructure.git
git remote set-url --add --push origin https://git-codecommit.<REGION>.amazonaws.com/v1/repos/distro-nation-infra

echo "✓ Multiple Git remotes configured for backup redundancy"

# Verify configuration
echo "Current remotes:"
git remote -v
```

#### Automated Repository Backup Script
```bash
#!/bin/bash
# git-repository-backup.sh
# Automated backup of Git repositories to multiple locations

set -e

BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_BASE_DIR="./infrastructure-backups"
BACKUP_DIR="$BACKUP_BASE_DIR/$BACKUP_TIMESTAMP"

echo "Starting Infrastructure Repository Backup - $BACKUP_TIMESTAMP"

mkdir -p "$BACKUP_DIR"

# 1. Create bare repository backup
echo "Creating bare repository backup..."
git clone --bare . "$BACKUP_DIR/infrastructure-repo.git"

# 2. Export all branches and tags
echo "Exporting branches and tags..."
cd "$BACKUP_DIR"

# Export all branches
git --git-dir=infrastructure-repo.git branch -a > branches.txt

# Export all tags  
git --git-dir=infrastructure-repo.git tag -l > tags.txt

# Export commit history summary
git --git-dir=infrastructure-repo.git log --oneline --graph --all > commit-history.txt

cd - > /dev/null

# 3. Create source code archive
echo "Creating source code archive..."
git archive --format=tar.gz --prefix=source-code/ HEAD > "$BACKUP_DIR/source-code-$BACKUP_TIMESTAMP.tar.gz"

# 4. Export Git configuration
echo "Backing up Git configuration..."
cp .git/config "$BACKUP_DIR/git-config.txt" 2>/dev/null || echo "No custom Git config found"

# 5. Create infrastructure inventory
echo "Creating infrastructure inventory..."
cat > "$BACKUP_DIR/infrastructure-inventory.md" << EOF
# Infrastructure Repository Backup

**Backup Date:** $(date)  
**Backup Location:** $BACKUP_DIR  
**Repository:** $(git remote get-url origin 2>/dev/null || echo "Local repository")

## Repository Statistics
- **Total Commits:** $(git rev-list --all --count)
- **Branches:** $(git branch -a | wc -l)
- **Tags:** $(git tag | wc -l)
- **Contributors:** $(git log --format='%an' | sort -u | wc -l)

## Latest Commits (Last 10)
$(git log --oneline -10)

## Branch Structure
$(git branch -a)

## Infrastructure Components
$(find . -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "*.tf" | head -20)

## Recovery Instructions
1. Clone bare repository: \`git clone infrastructure-repo.git recovered-infrastructure\`
2. Extract source archive: \`tar -xzf source-code-$BACKUP_TIMESTAMP.tar.gz\`
3. Restore Git remotes and configuration
4. Verify infrastructure templates and configurations

EOF

# 6. Push to backup remotes
echo "Pushing to backup remotes..."
REMOTES=("github-backup" "aws-codecommit" "gitlab-backup")

for remote in "${REMOTES[@]}"; do
  if git remote | grep -q "^$remote$"; then
    echo "Pushing to $remote..."
    git push "$remote" --all 2>/dev/null || echo "⚠ Failed to push to $remote"
    git push "$remote" --tags 2>/dev/null || echo "⚠ Failed to push tags to $remote"
  else
    echo "⚠ Remote $remote not configured"
  fi
done

# 7. Create backup summary
cat > "$BACKUP_DIR/backup-summary.json" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
  "backupLocation": "$BACKUP_DIR",
  "repository": {
    "url": "$(git remote get-url origin 2>/dev/null || echo 'local')",
    "branch": "$(git branch --show-current)",
    "commit": "$(git rev-parse HEAD)",
    "commits": $(git rev-list --all --count),
    "branches": $(git branch -a | wc -l),
    "tags": $(git tag | wc -l)
  },
  "backup_components": [
    "bare_repository",
    "source_archive", 
    "git_configuration",
    "infrastructure_inventory"
  ],
  "retention": "1 year",
  "next_backup": "$(date -d '+1 day' -u +%Y-%m-%dT%H:%M:%S.000Z)"
}
EOF

echo "✓ Repository backup completed: $BACKUP_DIR"
echo "Backup size: $(du -sh $BACKUP_DIR | cut -f1)"
```

### 1.2 Infrastructure Template Backup

#### CloudFormation Template Extraction
```bash
#!/bin/bash
# cloudformation-template-backup.sh
# Backup all CloudFormation templates and stack configurations

BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="./infrastructure-backups/$BACKUP_TIMESTAMP/cloudformation"

echo "Backing up CloudFormation templates and stacks..."

mkdir -p "$BACKUP_DIR"

# Get all CloudFormation stacks
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
  --query 'StackSummaries[].StackName' \
  --output text > "$BACKUP_DIR/active-stacks.txt"

ACTIVE_STACKS=($(cat "$BACKUP_DIR/active-stacks.txt"))

echo "Found ${#ACTIVE_STACKS[@]} active CloudFormation stacks"

# Backup each stack
for stack in "${ACTIVE_STACKS[@]}"; do
  echo "Backing up stack: $stack"
  
  stack_dir="$BACKUP_DIR/stacks/$stack"
  mkdir -p "$stack_dir"
  
  # Get stack template
  aws cloudformation get-template \
    --stack-name "$stack" \
    --query 'TemplateBody' > "$stack_dir/template.json"
  
  # Get stack parameters
  aws cloudformation describe-stacks \
    --stack-name "$stack" \
    --query 'Stacks[0].Parameters' > "$stack_dir/parameters.json"
  
  # Get stack outputs
  aws cloudformation describe-stacks \
    --stack-name "$stack" \
    --query 'Stacks[0].Outputs' > "$stack_dir/outputs.json"
  
  # Get stack tags
  aws cloudformation describe-stacks \
    --stack-name "$stack" \
    --query 'Stacks[0].Tags' > "$stack_dir/tags.json"
  
  # Get stack events (last 100)
  aws cloudformation describe-stack-events \
    --stack-name "$stack" \
    --max-items 100 \
    --query 'StackEvents' > "$stack_dir/events.json"
  
  # Create stack summary
  cat > "$stack_dir/stack-summary.md" << EOF
# CloudFormation Stack: $stack

**Backup Date:** $(date)  
**Stack Status:** $(aws cloudformation describe-stacks --stack-name "$stack" --query 'Stacks[0].StackStatus' --output text)  
**Creation Time:** $(aws cloudformation describe-stacks --stack-name "$stack" --query 'Stacks[0].CreationTime' --output text)  
**Last Updated:** $(aws cloudformation describe-stacks --stack-name "$stack" --query 'Stacks[0].LastUpdatedTime' --output text)

## Files Included:
- template.json: Stack template
- parameters.json: Stack parameters
- outputs.json: Stack outputs  
- tags.json: Stack tags
- events.json: Recent stack events

## Recovery Command:
\`\`\`bash
aws cloudformation create-stack \\
  --stack-name $stack-recovered \\
  --template-body file://template.json \\
  --parameters file://parameters.json \\
  --tags file://tags.json \\
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
\`\`\`
EOF

done

# Create overall CloudFormation backup summary
cat > "$BACKUP_DIR/cloudformation-summary.md" << EOF
# CloudFormation Infrastructure Backup

**Backup Date:** $(date)  
**Total Stacks:** ${#ACTIVE_STACKS[@]}  
**Backup Location:** $BACKUP_DIR

## Active Stacks:
$(printf '%s\n' "${ACTIVE_STACKS[@]}")

## Backup Contents:
- Stack templates (JSON format)
- Stack parameters and configurations
- Stack outputs and tags
- Recent stack events
- Recovery instructions

## Mass Recovery Script:
See \`mass-recovery.sh\` for automated stack recovery procedures.

EOF

# Create mass recovery script
cat > "$BACKUP_DIR/mass-recovery.sh" << 'EOF'
#!/bin/bash
# mass-recovery.sh
# Recover all CloudFormation stacks from backup

RECOVERY_SUFFIX="${1:-recovered}"

echo "Starting mass CloudFormation stack recovery..."

for stack_dir in stacks/*/; do
  if [ -d "$stack_dir" ]; then
    stack_name=$(basename "$stack_dir")
    recovery_name="$stack_name-$RECOVERY_SUFFIX"
    
    echo "Recovering stack: $stack_name -> $recovery_name"
    
    aws cloudformation create-stack \
      --stack-name "$recovery_name" \
      --template-body "file://$stack_dir/template.json" \
      --parameters "file://$stack_dir/parameters.json" \
      --tags "file://$stack_dir/tags.json" \
      --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
      --on-failure ROLLBACK
      
    echo "Stack $recovery_name creation initiated"
  fi
done

echo "Mass recovery completed. Monitor stack creation progress in AWS Console."
EOF

chmod +x "$BACKUP_DIR/mass-recovery.sh"

echo "✓ CloudFormation backup completed: $BACKUP_DIR"
```

#### CDK Application Backup
```bash
#!/bin/bash
# cdk-application-backup.sh
# Backup CDK applications, synthesized templates, and deployment state

BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="./infrastructure-backups/$BACKUP_TIMESTAMP/cdk"

echo "Backing up CDK applications and synthesized templates..."

mkdir -p "$BACKUP_DIR"

# Find CDK applications (directories with cdk.json)
CDK_APPS=($(find . -name "cdk.json" -exec dirname {} \;))

echo "Found ${#CDK_APPS[@]} CDK applications"

for app_path in "${CDK_APPS[@]}"; do
  app_name=$(basename "$app_path")
  app_backup_dir="$BACKUP_DIR/apps/$app_name"
  
  echo "Backing up CDK app: $app_name"
  
  mkdir -p "$app_backup_dir"
  
  # Copy CDK source code
  cp -r "$app_path"/* "$app_backup_dir/"
  
  # Synthesize CDK templates
  cd "$app_path"
  
  if command -v cdk &> /dev/null; then
    echo "Synthesizing CDK templates for $app_name..."
    
    # Create synth output directory
    synth_dir="$app_backup_dir/synthesized"
    mkdir -p "$synth_dir"
    
    # Synthesize all stacks
    cdk synth --output "$synth_dir" 2>/dev/null || echo "⚠ CDK synth failed for $app_name"
    
    # List CDK stacks
    cdk list > "$app_backup_dir/cdk-stacks.txt" 2>/dev/null || echo "No stacks found"
    
    # Get CDK context
    if [ -f "cdk.context.json" ]; then
      cp cdk.context.json "$app_backup_dir/"
    fi
    
    # Create deployment instructions
    cat > "$app_backup_dir/deployment-instructions.md" << EOF
# CDK Application: $app_name

**Backup Date:** $(date)  
**CDK Version:** $(cdk --version 2>/dev/null || echo "Unknown")  
**Node Version:** $(node --version 2>/dev/null || echo "Unknown")

## Stacks in this Application:
$(cat "$app_backup_dir/cdk-stacks.txt" 2>/dev/null || echo "Unable to determine stacks")

## Recovery Steps:
1. Install CDK: \`npm install -g aws-cdk\`
2. Install dependencies: \`npm install\`
3. Bootstrap CDK (if needed): \`cdk bootstrap\`
4. Deploy stacks: \`cdk deploy --all\`

## Files Included:
- Source code: All TypeScript/JavaScript files
- synthesized/: CloudFormation templates
- cdk.context.json: CDK context and cached values
- package.json: Dependencies and scripts
EOF

  else
    echo "⚠ CDK CLI not available, skipping synthesis"
  fi
  
  cd - > /dev/null
done

# Backup CDK global configuration
if [ -f ~/.cdk.json ]; then
  cp ~/.cdk.json "$BACKUP_DIR/global-cdk-config.json"
fi

# Create CDK backup summary
cat > "$BACKUP_DIR/cdk-summary.md" << EOF
# CDK Applications Backup

**Backup Date:** $(date)  
**CDK Applications Found:** ${#CDK_APPS[@]}  
**Backup Location:** $BACKUP_DIR

## Applications:
$(printf '%s\n' "${CDK_APPS[@]}" | sed 's|^|./|')

## Backup Contents:
- Source code for all CDK applications
- Synthesized CloudFormation templates
- CDK context and configuration
- Deployment instructions
- Global CDK configuration

## Recovery Process:
1. Restore source code from backup
2. Install CDK CLI and dependencies
3. Bootstrap CDK environment if needed
4. Deploy using \`cdk deploy\` commands

EOF

echo "✓ CDK backup completed: $BACKUP_DIR"
```

## 2. Deployment Pipeline Backup

### 2.1 GitHub Actions Workflow Backup

#### Workflow Configuration Backup
```bash
#!/bin/bash
# github-actions-backup.sh
# Backup GitHub Actions workflows and CI/CD configurations

BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="./infrastructure-backups/$BACKUP_TIMESTAMP/github-actions"

echo "Backing up GitHub Actions workflows and CI/CD configurations..."

mkdir -p "$BACKUP_DIR"

# 1. Backup workflow files
if [ -d ".github/workflows" ]; then
  echo "Copying GitHub Actions workflows..."
  cp -r .github/workflows "$BACKUP_DIR/"
  
  # List all workflow files
  find .github/workflows -name "*.yml" -o -name "*.yaml" > "$BACKUP_DIR/workflow-files.txt"
  
  # Analyze workflows
  cat > "$BACKUP_DIR/workflow-analysis.md" << EOF
# GitHub Actions Workflows Analysis

**Backup Date:** $(date)  
**Workflow Files:** $(find .github/workflows -name "*.yml" -o -name "*.yaml" | wc -l)

## Workflow Files:
$(cat "$BACKUP_DIR/workflow-files.txt")

## Workflows by Type:
$(grep -l "deploy" .github/workflows/*.yml 2>/dev/null | sed 's|.*/||' | sed 's/^/- Deployment: /' || echo "No deployment workflows found")
$(grep -l "test" .github/workflows/*.yml 2>/dev/null | sed 's|.*/||' | sed 's/^/- Testing: /' || echo "No test workflows found")
$(grep -l "build" .github/workflows/*.yml 2>/dev/null | sed 's|.*/||' | sed 's/^/- Build: /' || echo "No build workflows found")

EOF
else
  echo "⚠ No GitHub Actions workflows found"
fi

# 2. Backup GitHub configuration
if [ -d ".github" ]; then
  echo "Backing up GitHub configuration..."
  
  # Copy issue templates, PR templates, etc.
  find .github -type f ! -path ".github/workflows/*" -exec cp --parents {} "$BACKUP_DIR/" \;
fi

# 3. Extract secrets and environment variables (names only, not values)
echo "Documenting required secrets and environment variables..."

if [ -d ".github/workflows" ]; then
  # Extract secret references from workflows
  grep -h "secrets\." .github/workflows/*.yml 2>/dev/null | \
    sed 's/.*secrets\.\([A-Z_]*\).*/\1/' | \
    sort -u > "$BACKUP_DIR/required-secrets.txt" || touch "$BACKUP_DIR/required-secrets.txt"
  
  # Extract environment variable references
  grep -h "\${{ env\." .github/workflows/*.yml 2>/dev/null | \
    sed 's/.*env\.\([A-Z_]*\).*/\1/' | \
    sort -u > "$BACKUP_DIR/required-env-vars.txt" || touch "$BACKUP_DIR/required-env-vars.txt"
fi

# 4. Create restoration guide
cat > "$BACKUP_DIR/restoration-guide.md" << EOF
# GitHub Actions Restoration Guide

**Backup Date:** $(date)

## Required Secrets
The following secrets need to be configured in GitHub repository settings:
$([ -s "$BACKUP_DIR/required-secrets.txt" ] && cat "$BACKUP_DIR/required-secrets.txt" | sed 's/^/- /' || echo "No secrets found")

## Required Environment Variables
$([ -s "$BACKUP_DIR/required-env-vars.txt" ] && cat "$BACKUP_DIR/required-env-vars.txt" | sed 's/^/- /' || echo "No environment variables found")

## Restoration Steps:
1. Copy workflow files to \`.github/workflows/\` directory
2. Configure required secrets in GitHub repository settings
3. Set up environment variables in workflow files or repository settings
4. Test workflows with a sample commit
5. Verify deployment pipelines are working correctly

## Important Notes:
- Secret values are not backed up for security reasons
- Environment-specific configurations may need adjustment
- AWS/Firebase credentials need to be reconfigured
- Review and update any hardcoded values in workflows

EOF

echo "✓ GitHub Actions backup completed: $BACKUP_DIR"
```

### 2.2 Secrets and Configuration Management

#### Secrets Documentation and Management
```bash
#!/bin/bash
# secrets-documentation.sh
# Document secrets and configuration requirements (without exposing values)

BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="./infrastructure-backups/$BACKUP_TIMESTAMP/configuration"

echo "Documenting secrets and configuration management..."

mkdir -p "$BACKUP_DIR"

# 1. AWS Systems Manager Parameter Store documentation
echo "Documenting AWS Parameter Store parameters..."

aws ssm describe-parameters \
  --query 'Parameters[].{Name:Name,Type:Type,Description:Description}' \
  --output json > "$BACKUP_DIR/parameter-store-inventory.json"

# Create parameter restoration script
cat > "$BACKUP_DIR/restore-parameters.sh" << 'EOF'
#!/bin/bash
# restore-parameters.sh
# Restore AWS Systems Manager parameters from documentation

echo "This script template shows how to restore parameters."
echo "You must provide the actual parameter values."

# Example parameter restoration (replace with actual parameters)
while IFS= read -r param; do
  param_name=$(echo "$param" | jq -r '.Name')
  param_type=$(echo "$param" | jq -r '.Type')
  
  echo "Restore parameter: $param_name (Type: $param_type)"
  echo "aws ssm put-parameter --name '$param_name' --value 'YOUR_VALUE_HERE' --type '$param_type'"
  
done < <(jq -c '.[]' parameter-store-inventory.json)
EOF

chmod +x "$BACKUP_DIR/restore-parameters.sh"

# 2. AWS Secrets Manager documentation  
echo "Documenting AWS Secrets Manager secrets..."

aws secretsmanager list-secrets \
  --query 'SecretList[].{Name:Name,Description:Description,Tags:Tags}' \
  --output json > "$BACKUP_DIR/secrets-manager-inventory.json"

# 3. Firebase configuration documentation
echo "Documenting Firebase configuration requirements..."

if [ -f "firebase.json" ]; then
  cp firebase.json "$BACKUP_DIR/"
fi

if [ -f ".firebaserc" ]; then
  cp .firebaserc "$BACKUP_DIR/"
fi

# 4. Environment-specific configurations
echo "Documenting environment configurations..."

# Document different environment configurations
for env in development staging production; do
  if [ -f ".env.$env" ]; then
    # Copy structure but remove values for security
    sed 's/=.*/=<VALUE_REMOVED_FOR_SECURITY>/' ".env.$env" > "$BACKUP_DIR/env-$env-template.txt"
  fi
done

# 5. Create configuration restoration guide
cat > "$BACKUP_DIR/configuration-restoration-guide.md" << EOF
# Configuration and Secrets Restoration Guide

**Backup Date:** $(date)

## AWS Parameter Store
- **Inventory:** See \`parameter-store-inventory.json\`
- **Restoration:** Run \`restore-parameters.sh\` with actual values
- **Parameter Count:** $(jq length "$BACKUP_DIR/parameter-store-inventory.json" 2>/dev/null || echo "Unknown")

## AWS Secrets Manager  
- **Inventory:** See \`secrets-manager-inventory.json\`
- **Secret Count:** $(jq length "$BACKUP_DIR/secrets-manager-inventory.json" 2>/dev/null || echo "Unknown")

## Firebase Configuration
- **Project Config:** firebase.json (if present)
- **Project Selection:** .firebaserc (if present)

## Environment Variables
- **Templates:** env-*-template.txt files
- **Note:** Values removed for security, must be populated manually

## Critical Secrets to Restore:
1. AWS Access Keys and Roles
2. Firebase Service Account Keys
3. Database Connection Strings
4. API Keys (YouTube, Spotify, TikTok, etc.)
5. Encryption Keys
6. Third-party Service Credentials

## Security Considerations:
- Never store actual secret values in version control
- Use proper IAM roles and least privilege access
- Rotate secrets after restoration
- Verify all integrations after secret restoration

## Restoration Checklist:
- [ ] AWS Parameter Store parameters restored
- [ ] AWS Secrets Manager secrets restored  
- [ ] Firebase service account keys configured
- [ ] Environment variables populated
- [ ] CI/CD secrets configured
- [ ] Third-party API credentials verified
- [ ] Database access validated
- [ ] Application integrations tested

EOF

echo "✓ Configuration documentation completed: $BACKUP_DIR"
```

## 3. Infrastructure State Management

### 3.1 CloudFormation Stack Drift Detection

#### Automated Drift Detection and Backup
```bash
#!/bin/bash
# cloudformation-drift-backup.sh
# Detect and document CloudFormation stack drift

BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="./infrastructure-backups/$BACKUP_TIMESTAMP/drift-detection"

echo "Detecting CloudFormation stack drift and backing up current state..."

mkdir -p "$BACKUP_DIR"

# Get all active stacks
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
  --query 'StackSummaries[].StackName' \
  --output text > "$BACKUP_DIR/active-stacks.txt"

ACTIVE_STACKS=($(cat "$BACKUP_DIR/active-stacks.txt"))

echo "Checking drift for ${#ACTIVE_STACKS[@]} active stacks..."

drift_summary=()

for stack in "${ACTIVE_STACKS[@]}"; do
  echo "Checking drift for stack: $stack"
  
  stack_dir="$BACKUP_DIR/stacks/$stack"
  mkdir -p "$stack_dir"
  
  # Initiate drift detection
  drift_detection_id=$(aws cloudformation detect-stack-drift \
    --stack-name "$stack" \
    --query 'StackDriftDetectionId' \
    --output text)
  
  echo "Drift detection initiated: $drift_detection_id"
  
  # Wait for drift detection to complete
  echo "Waiting for drift detection to complete..."
  aws cloudformation wait stack-drift-detection-complete \
    --stack-drift-detection-id "$drift_detection_id"
  
  # Get drift detection results
  aws cloudformation describe-stack-drift-detection \
    --stack-drift-detection-id "$drift_detection_id" > "$stack_dir/drift-detection-result.json"
  
  # Get resource drift details
  aws cloudformation describe-stack-resource-drifts \
    --stack-name "$stack" > "$stack_dir/resource-drifts.json"
  
  # Determine drift status
  drift_status=$(jq -r '.StackDriftStatus' "$stack_dir/drift-detection-result.json")
  drifted_resources=$(jq '[.StackResourceDrifts[] | select(.StackResourceDriftStatus != "IN_SYNC")] | length' "$stack_dir/resource-drifts.json")
  
  drift_summary+=("$stack:$drift_status:$drifted_resources")
  
  # Create drift report for this stack
  cat > "$stack_dir/drift-report.md" << EOF
# Stack Drift Report: $stack

**Detection Date:** $(date)  
**Stack Status:** $drift_status  
**Drifted Resources:** $drifted_resources

## Drift Detection Results:
$(jq -r '.' "$stack_dir/drift-detection-result.json")

## Resource Drift Details:
$(jq -r '.StackResourceDrifts[] | select(.StackResourceDriftStatus != "IN_SYNC") | "- \(.LogicalResourceId) (\(.ResourceType)): \(.StackResourceDriftStatus)"' "$stack_dir/resource-drifts.json" 2>/dev/null || echo "No drifted resources found")

## Remediation Actions:
1. Review drifted resources in AWS Console
2. Update CloudFormation template to match current state, or
3. Execute stack update to revert manual changes
4. Consider implementing drift detection automation

EOF

  echo "✓ Drift detection completed for $stack: $drift_status ($drifted_resources drifted resources)"
done

# Create overall drift summary
cat > "$BACKUP_DIR/drift-summary.md" << EOF
# Infrastructure Drift Detection Summary

**Detection Date:** $(date)  
**Stacks Checked:** ${#ACTIVE_STACKS[@]}

## Drift Status Overview:
$(printf '%s\n' "${drift_summary[@]}" | while IFS=: read stack status resources; do
  echo "- **$stack**: $status ($resources drifted resources)"
done)

## Stacks with Drift:
$(printf '%s\n' "${drift_summary[@]}" | while IFS=: read stack status resources; do
  if [ "$status" != "IN_SYNC" ] && [ "$resources" -gt 0 ]; then
    echo "- $stack: $resources resources drifted"
  fi
done)

## Remediation Priority:
1. **High Priority**: Stacks with DRIFTED status and security-related resources
2. **Medium Priority**: Stacks with DRIFTED status and operational resources
3. **Low Priority**: Stacks with drift in non-critical resources

## Next Steps:
1. Review individual stack drift reports in \`stacks/\` subdirectories
2. Plan remediation for drifted stacks
3. Implement automated drift detection and alerting
4. Update infrastructure as code templates as needed

EOF

# Create drift remediation script
cat > "$BACKUP_DIR/remediate-drift.sh" << 'EOF'
#!/bin/bash
# remediate-drift.sh
# Remediate CloudFormation stack drift

STACK_NAME="$1"
ACTION="$2"  # "update" or "revert"

if [ -z "$STACK_NAME" ] || [ -z "$ACTION" ]; then
  echo "Usage: $0 <stack-name> <update|revert>"
  echo ""
  echo "Actions:"
  echo "  update: Update CloudFormation template to match current state"
  echo "  revert: Update stack to revert manual changes"
  exit 1
fi

echo "Remediating drift for stack: $STACK_NAME"
echo "Action: $ACTION"

case "$ACTION" in
  "update")
    echo "Manual action required:"
    echo "1. Review current stack resources in AWS Console"
    echo "2. Update CloudFormation template to match current state"
    echo "3. Test template in staging environment"
    echo "4. Deploy updated template to production"
    ;;
  "revert")
    echo "Reverting manual changes by updating stack..."
    aws cloudformation update-stack \
      --stack-name "$STACK_NAME" \
      --use-previous-template \
      --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
    
    echo "Stack update initiated. Monitor progress in AWS Console."
    ;;
  *)
    echo "Invalid action: $ACTION"
    exit 1
    ;;
esac
EOF

chmod +x "$BACKUP_DIR/remediate-drift.sh"

echo "✓ Infrastructure drift detection completed: $BACKUP_DIR"
```

### 3.2 Resource State Documentation

#### Infrastructure Resource Inventory
```python
#!/usr/bin/env python3
# infrastructure-inventory.py
# Create comprehensive infrastructure resource inventory

import boto3
import json
from datetime import datetime
import os

def get_ec2_resources():
    """Get EC2 instances, volumes, and networking resources"""
    ec2 = boto3.client('ec2')
    
    resources = {
        'instances': [],
        'volumes': [],
        'security_groups': [],
        'vpcs': [],
        'subnets': []
    }
    
    # EC2 Instances
    instances = ec2.describe_instances()
    for reservation in instances['Reservations']:
        for instance in reservation['Instances']:
            resources['instances'].append({
                'instance_id': instance['InstanceId'],
                'instance_type': instance['InstanceType'],
                'state': instance['State']['Name'],
                'vpc_id': instance.get('VpcId'),
                'subnet_id': instance.get('SubnetId'),
                'tags': instance.get('Tags', [])
            })
    
    # EBS Volumes
    volumes = ec2.describe_volumes()
    for volume in volumes['Volumes']:
        resources['volumes'].append({
            'volume_id': volume['VolumeId'],
            'size': volume['Size'],
            'volume_type': volume['VolumeType'],
            'state': volume['State'],
            'encrypted': volume['Encrypted'],
            'tags': volume.get('Tags', [])
        })
    
    # Security Groups
    sgs = ec2.describe_security_groups()
    for sg in sgs['SecurityGroups']:
        resources['security_groups'].append({
            'group_id': sg['GroupId'],
            'group_name': sg['GroupName'],
            'vpc_id': sg['VpcId'],
            'description': sg['Description'],
            'rules_count': len(sg['IpPermissions']) + len(sg['IpPermissionsEgress'])
        })
    
    return resources

def get_lambda_functions():
    """Get Lambda function inventory"""
    lambda_client = boto3.client('lambda')
    
    functions = []
    paginator = lambda_client.get_paginator('list_functions')
    
    for page in paginator.paginate():
        for function in page['Functions']:
            functions.append({
                'function_name': function['FunctionName'],
                'runtime': function['Runtime'],
                'handler': function['Handler'],
                'memory_size': function['MemorySize'],
                'timeout': function['Timeout'],
                'last_modified': function['LastModified']
            })
    
    return functions

def get_s3_buckets():
    """Get S3 bucket inventory"""
    s3 = boto3.client('s3')
    
    buckets = []
    bucket_list = s3.list_buckets()
    
    for bucket in bucket_list['Buckets']:
        bucket_name = bucket['Name']
        
        try:
            # Get bucket location
            location = s3.get_bucket_location(Bucket=bucket_name)
            region = location['LocationConstraint'] or '<REGION>'
            
            # Get bucket versioning
            versioning = s3.get_bucket_versioning(Bucket=bucket_name)
            
            # Get bucket size (approximate)
            cloudwatch = boto3.client('cloudwatch', region_name=region)
            try:
                metrics = cloudwatch.get_metric_statistics(
                    Namespace='AWS/S3',
                    MetricName='BucketSizeBytes',
                    Dimensions=[
                        {'Name': 'BucketName', 'Value': bucket_name},
                        {'Name': 'StorageType', 'Value': 'StandardStorage'}
                    ],
                    StartTime=datetime.now().replace(hour=0, minute=0, second=0),
                    EndTime=datetime.now(),
                    Period=86400,
                    Statistics=['Average']
                )
                
                size_bytes = metrics['Datapoints'][0]['Average'] if metrics['Datapoints'] else 0
            except:
                size_bytes = 0
            
            buckets.append({
                'bucket_name': bucket_name,
                'creation_date': bucket['CreationDate'].isoformat(),
                'region': region,
                'versioning': versioning.get('Status', 'Disabled'),
                'size_bytes': int(size_bytes),
                'size_gb': round(size_bytes / (1024**3), 2)
            })
            
        except Exception as e:
            buckets.append({
                'bucket_name': bucket_name,
                'creation_date': bucket['CreationDate'].isoformat(),
                'error': str(e)
            })
    
    return buckets

def get_rds_resources():
    """Get RDS database inventory"""
    rds = boto3.client('rds')
    
    resources = {
        'db_instances': [],
        'db_clusters': []
    }
    
    # DB Instances
    instances = rds.describe_db_instances()
    for instance in instances['DBInstances']:
        resources['db_instances'].append({
            'db_instance_identifier': instance['DBInstanceIdentifier'],
            'db_instance_class': instance['DBInstanceClass'],
            'engine': instance['Engine'],
            'engine_version': instance['EngineVersion'],
            'status': instance['DBInstanceStatus'],
            'allocated_storage': instance.get('AllocatedStorage'),
            'multi_az': instance['MultiAZ']
        })
    
    # DB Clusters (Aurora)
    clusters = rds.describe_db_clusters()
    for cluster in clusters['DBClusters']:
        resources['db_clusters'].append({
            'db_cluster_identifier': cluster['DBClusterIdentifier'],
            'engine': cluster['Engine'],
            'engine_version': cluster['EngineVersion'],
            'status': cluster['Status'],
            'backup_retention_period': cluster['BackupRetentionPeriod'],
            'members': len(cluster['DBClusterMembers'])
        })
    
    return resources

def create_infrastructure_inventory():
    """Create comprehensive infrastructure inventory"""
    timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
    backup_dir = f'./infrastructure-backups/{timestamp}/inventory'
    
    os.makedirs(backup_dir, exist_ok=True)
    
    print("Creating infrastructure inventory...")
    
    inventory = {
        'timestamp': datetime.now().isoformat(),
        'account_id': boto3.client('sts').get_caller_identity()['Account'],
        'region': boto3.Session().region_name or '<REGION>'
    }
    
    # Collect resource inventories
    print("Collecting EC2 resources...")
    inventory['ec2'] = get_ec2_resources()
    
    print("Collecting Lambda functions...")
    inventory['lambda'] = get_lambda_functions()
    
    print("Collecting S3 buckets...")
    inventory['s3'] = get_s3_buckets()
    
    print("Collecting RDS resources...")
    inventory['rds'] = get_rds_resources()
    
    # Save complete inventory
    inventory_file = os.path.join(backup_dir, 'infrastructure-inventory.json')
    with open(inventory_file, 'w') as f:
        json.dump(inventory, f, indent=2, default=str)
    
    # Create summary report
    summary_file = os.path.join(backup_dir, 'inventory-summary.md')
    with open(summary_file, 'w') as f:
        f.write(f"""# Infrastructure Inventory Summary

**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  
**Account ID:** {inventory['account_id']}  
**Region:** {inventory['region']}

## Resource Counts:
- **EC2 Instances:** {len(inventory['ec2']['instances'])}
- **EBS Volumes:** {len(inventory['ec2']['volumes'])}
- **Security Groups:** {len(inventory['ec2']['security_groups'])}
- **Lambda Functions:** {len(inventory['lambda'])}
- **S3 Buckets:** {len(inventory['s3'])}
- **RDS Instances:** {len(inventory['rds']['db_instances'])}
- **RDS Clusters:** {len(inventory['rds']['db_clusters'])}

## Storage Summary:
- **Total S3 Storage:** {sum(bucket.get('size_gb', 0) for bucket in inventory['s3'])} GB
- **EBS Storage:** {sum(vol.get('size', 0) for vol in inventory['ec2']['volumes'])} GB

## Active Resources:
- **Running EC2 Instances:** {len([i for i in inventory['ec2']['instances'] if i['state'] == 'running'])}
- **Available RDS Instances:** {len([i for i in inventory['rds']['db_instances'] if i['status'] == 'available'])}

## Files Generated:
- infrastructure-inventory.json: Complete resource inventory
- inventory-summary.md: This summary report

""")
    
    print(f"✓ Infrastructure inventory completed: {backup_dir}")
    return inventory_file

if __name__ == '__main__':
    create_infrastructure_inventory()
```

## 4. Automated Recovery Procedures

### 4.1 Infrastructure Recovery Orchestration

#### Master Recovery Script
```bash
#!/bin/bash
# infrastructure-recovery.sh
# Orchestrated infrastructure recovery from backup

set -e

BACKUP_DATE="$1"
RECOVERY_TYPE="$2"  # full, partial, or test
DRY_RUN="${3:-true}"

if [ -z "$BACKUP_DATE" ] || [ -z "$RECOVERY_TYPE" ]; then
  echo "Usage: $0 <backup-date> <full|partial|test> [dry-run]"
  echo ""
  echo "Examples:"
  echo "  $0 20250725-120000 full false"
  echo "  $0 20250725-120000 test true"
  exit 1
fi

BACKUP_DIR="./infrastructure-backups/$BACKUP_DATE"
RECOVERY_LOG="./infrastructure-recovery-${BACKUP_DATE}-$(date +%H%M%S).log"

echo "=== Infrastructure Recovery Started ===" | tee "$RECOVERY_LOG"
echo "Backup Date: $BACKUP_DATE" | tee -a "$RECOVERY_LOG"
echo "Recovery Type: $RECOVERY_TYPE" | tee -a "$RECOVERY_LOG"
echo "Dry Run: $DRY_RUN" | tee -a "$RECOVERY_LOG"
echo "Recovery Log: $RECOVERY_LOG" | tee -a "$RECOVERY_LOG"

# Verify backup exists
if [ ! -d "$BACKUP_DIR" ]; then
  echo "ERROR: Backup directory not found: $BACKUP_DIR" | tee -a "$RECOVERY_LOG"
  exit 1
fi

# Recovery status tracking
declare -A recovery_results

log_recovery_result() {
  local component=$1
  local status=$2
  local message=$3
  
  recovery_results[$component]=$status
  echo "[$component] $status: $message" | tee -a "$RECOVERY_LOG"
}

# Phase 1: Pre-recovery validation
echo "--- Phase 1: Pre-recovery Validation ---" | tee -a "$RECOVERY_LOG"

if [ -f "$BACKUP_DIR/backup-summary.json" ]; then
  echo "✓ Backup summary found" | tee -a "$RECOVERY_LOG"
  backup_timestamp=$(jq -r '.timestamp' "$BACKUP_DIR/backup-summary.json")
  echo "Backup timestamp: $backup_timestamp" | tee -a "$RECOVERY_LOG"
else
  echo "⚠ Backup summary not found" | tee -a "$RECOVERY_LOG"
fi

# Phase 2: Infrastructure recovery
echo "--- Phase 2: Infrastructure Recovery ---" | tee -a "$RECOVERY_LOG"

# CloudFormation recovery
if [ -d "$BACKUP_DIR/cloudformation" ]; then
  echo "Recovering CloudFormation stacks..." | tee -a "$RECOVERY_LOG"
  
  if [ "$DRY_RUN" = "false" ]; then
    cd "$BACKUP_DIR/cloudformation"
    ./mass-recovery.sh "recovered-$(date +%Y%m%d)" >> "$RECOVERY_LOG" 2>&1
    recovery_status=$?
    cd - > /dev/null
    
    if [ $recovery_status -eq 0 ]; then
      log_recovery_result "CloudFormation" "SUCCESS" "Stacks recovery initiated"
    else
      log_recovery_result "CloudFormation" "FAILED" "Stack recovery failed"
    fi
  else
    log_recovery_result "CloudFormation" "DRY_RUN" "Would recover CloudFormation stacks"
  fi
else
  log_recovery_result "CloudFormation" "SKIPPED" "No CloudFormation backup found"
fi

# CDK recovery
if [ -d "$BACKUP_DIR/cdk" ]; then
  echo "Recovering CDK applications..." | tee -a "$RECOVERY_LOG"
  
  if [ "$DRY_RUN" = "false" ]; then
    # This would require manual intervention for CDK deployment
    log_recovery_result "CDK" "MANUAL" "CDK recovery requires manual deployment"
  else
    log_recovery_result "CDK" "DRY_RUN" "Would recover CDK applications"
  fi
else
  log_recovery_result "CDK" "SKIPPED" "No CDK backup found"
fi

# Phase 3: Application recovery
echo "--- Phase 3: Application Recovery ---" | tee -a "$RECOVERY_LOG"

# Lambda functions (handled by CloudFormation/CDK)
log_recovery_result "Lambda" "DELEGATED" "Lambda functions recovered via CloudFormation"

# S3 buckets (handled by CloudFormation, data restored separately)
log_recovery_result "S3" "DELEGATED" "S3 buckets recovered via CloudFormation, data restoration separate"

# Phase 4: Configuration recovery
echo "--- Phase 4: Configuration Recovery ---" | tee -a "$RECOVERY_LOG"

if [ -d "$BACKUP_DIR/configuration" ]; then
  echo "Configuration templates available for manual restoration" | tee -a "$RECOVERY_LOG"
  log_recovery_result "Configuration" "MANUAL" "Secrets and parameters require manual restoration"
else
  log_recovery_result "Configuration" "SKIPPED" "No configuration backup found"
fi

# Phase 5: CI/CD recovery
echo "--- Phase 5: CI/CD Recovery ---" | tee -a "$RECOVERY_LOG"

if [ -d "$BACKUP_DIR/github-actions" ]; then
  echo "GitHub Actions workflows available for restoration" | tee -a "$RECOVERY_LOG"
  log_recovery_result "CI_CD" "MANUAL" "GitHub Actions require manual repository setup"
else
  log_recovery_result "CI_CD" "SKIPPED" "No CI/CD backup found"
fi

# Phase 6: Validation
echo "--- Phase 6: Recovery Validation ---" | tee -a "$RECOVERY_LOG"

if [ "$DRY_RUN" = "false" ]; then
  echo "Running post-recovery validation..." | tee -a "$RECOVERY_LOG"
  
  # Check CloudFormation stacks
  aws cloudformation list-stacks \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
    --query 'StackSummaries[?contains(StackName, `recovered`)].StackName' \
    --output text > "/tmp/recovered-stacks.txt"
  
  recovered_stacks=$(wc -l < "/tmp/recovered-stacks.txt")
  echo "Recovered CloudFormation stacks: $recovered_stacks" | tee -a "$RECOVERY_LOG"
  
  log_recovery_result "Validation" "COMPLETED" "Post-recovery validation completed"
else
  log_recovery_result "Validation" "SKIPPED" "Validation skipped in dry run mode"
fi

# Generate recovery summary
echo "--- Recovery Summary ---" | tee -a "$RECOVERY_LOG"

successful_recoveries=0
failed_recoveries=0
manual_recoveries=0

for status in "${recovery_results[@]}"; do
  case "$status" in
    "SUCCESS") ((successful_recoveries++));;
    "FAILED") ((failed_recoveries++));;
    "MANUAL") ((manual_recoveries++));;
  esac
done

total_components=${#recovery_results[@]}

echo "Total Components: $total_components" | tee -a "$RECOVERY_LOG"
echo "Successful: $successful_recoveries" | tee -a "$RECOVERY_LOG"
echo "Failed: $failed_recoveries" | tee -a "$RECOVERY_LOG"
echo "Manual Required: $manual_recoveries" | tee -a "$RECOVERY_LOG"

# Create manual recovery checklist
cat > "./manual-recovery-checklist-$BACKUP_DATE.md" << EOF
# Manual Recovery Checklist

**Recovery Date:** $(date)  
**Backup Date:** $BACKUP_DATE  
**Recovery Type:** $RECOVERY_TYPE

## Automated Recovery Results:
$(for component in "${!recovery_results[@]}"; do
  echo "- **$component**: ${recovery_results[$component]}"
done)

## Manual Recovery Required:

### 1. Secrets and Configuration
- [ ] Restore AWS Parameter Store parameters
- [ ] Restore AWS Secrets Manager secrets
- [ ] Configure Firebase service account keys
- [ ] Update environment variables
- [ ] Test database connections

### 2. GitHub Actions and CI/CD
- [ ] Restore .github/workflows/ directory
- [ ] Configure GitHub repository secrets
- [ ] Test deployment pipelines
- [ ] Verify environment-specific configurations

### 3. CDK Applications
- [ ] Deploy CDK applications manually
- [ ] Verify CDK context and configuration
- [ ] Test CDK deployment process

### 4. Data Recovery
- [ ] Restore Aurora PostgreSQL data (if needed)
- [ ] Restore S3 bucket contents (if needed)  
- [ ] Restore Firebase data (if needed)
- [ ] Verify data integrity

### 5. DNS and External Services
- [ ] Update DNS records if needed
- [ ] Verify external integrations
- [ ] Update third-party service configurations
- [ ] Test API endpoints

### 6. Monitoring and Alerting
- [ ] Verify CloudWatch alarms
- [ ] Test notification channels
- [ ] Update monitoring dashboards
- [ ] Verify backup schedules

## Validation Tests:
- [ ] Application accessibility
- [ ] Database connectivity
- [ ] API functionality
- [ ] File upload/download
- [ ] Authentication systems
- [ ] External integrations

EOF

echo "✓ Manual recovery checklist created: ./manual-recovery-checklist-$BACKUP_DATE.md" | tee -a "$RECOVERY_LOG"

# Send notification
if command -v aws &> /dev/null; then
  aws sns publish \
    --topic-arn "arn:aws:sns:<REGION>:<AWS_ACCOUNT_ID>:infrastructure-recovery-alerts" \
    --message "Infrastructure recovery $RECOVERY_TYPE completed for backup $BACKUP_DATE. Check recovery log: $RECOVERY_LOG" \
    --subject "Infrastructure Recovery Completed" 2>/dev/null || echo "Failed to send notification"
fi

echo "=== Infrastructure Recovery Completed ===" | tee -a "$RECOVERY_LOG"
echo "Recovery log: $RECOVERY_LOG" | tee -a "$RECOVERY_LOG"
echo "Manual checklist: ./manual-recovery-checklist-$BACKUP_DATE.md" | tee -a "$RECOVERY_LOG"

# Exit with appropriate code
if [ $failed_recoveries -gt 0 ]; then
  exit 1
else
  exit 0
fi
```

## Implementation Schedule

### Phase 1: Documentation and Basic Backup (Week 1)
```yaml
✅ Complete Infrastructure as Code backup procedures documentation
⏳ Implement Git repository backup with multiple remotes
⏳ Set up CloudFormation template backup automation
⏳ Create CDK application backup procedures
⏳ Document secrets and configuration management
```

### Phase 2: Advanced Backup and Monitoring (Week 2)
```yaml
⏳ Implement stack drift detection and backup
⏳ Create infrastructure resource inventory automation
⏳ Set up GitHub Actions workflow backup
⏳ Implement automated backup validation
```

### Phase 3: Recovery and Testing (Week 3-4)
```yaml
⏳ Create infrastructure recovery orchestration
⏳ Implement recovery testing procedures
⏳ Set up backup monitoring and alerting
⏳ Create comprehensive recovery runbooks
```

## Next Steps

### Immediate Actions
1. ✅ Complete IaC backup strategy documentation
2. ⏳ Set up Git repository backup with multiple remotes
3. ⏳ Implement CloudFormation stack backup automation
4. ⏳ Create secrets documentation templates

### Integration with Disaster Recovery Plan
1. ⏳ Coordinate with database and application backup procedures
2. ⏳ Integrate with Empire Distribution standards
3. ⏳ Establish unified backup testing schedule
4. ⏳ Create cross-component recovery dependencies mapping

---

**Document Version**: 1.0  
**Last Updated**: July 25, 2025  
**Next Review**: October 25, 2025  
**Owner**: Adrian Green, Head of Engineering  
**Status**: Phase 1 Implementation

*This document contains critical infrastructure backup and recovery procedures. Ensure proper security when handling infrastructure templates and configuration data.*