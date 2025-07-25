# S3 Storage Backup and Versioning Strategies

## Overview
This document outlines comprehensive backup and versioning strategies for Amazon S3 storage across Distro Nation's 23+ S3 buckets, ensuring data protection, compliance, and rapid recovery capabilities for all stored assets including audio files, user uploads, profile pictures, and application data.

## Executive Summary

### Current S3 Infrastructure
```yaml
Total Buckets: 23+ buckets
Storage Usage: ~709 GB across all buckets
Monthly Cost: $16.61 (Standard storage)
Key Buckets:
  - distronation-audio: ~500GB (audio files)
  - distro-nation-upload: ~200GB (user uploads)
  - distronationfm-profile-pictures: ~10GB (user profiles)
  - distronation-backup: Backup storage
  - distronation-reporting: Analytics data
```

### Backup Strategy Summary
- **Versioning**: Enabled on critical buckets with lifecycle management
- **Cross-Region Replication**: Implemented for business-critical data
- **Lifecycle Policies**: Automated transition to cost-effective storage classes
- **Recovery Time Objective**: 15-30 minutes for critical data restoration
- **Recovery Point Objective**: Zero data loss with versioning enabled

## 1. S3 Bucket Classification and Strategy

### 1.1 Bucket Risk Assessment

#### Critical Buckets (Tier 1) - Zero Data Loss Tolerance
```yaml
distronation-audio:
  Purpose: Audio file storage for music distribution
  Current Size: ~500GB
  Growth Rate: ~50GB/month
  Business Impact: HIGH - Revenue generating content
  Backup Strategy: Versioning + Cross-region replication + Glacier backup
  
distro-nation-upload:
  Purpose: User file uploads and content submission
  Current Size: ~200GB  
  Growth Rate: ~20GB/month
  Business Impact: HIGH - User generated content
  Backup Strategy: Versioning + Cross-region replication + Intelligent tiering
  
distronationfm-profile-pictures:
  Purpose: User profile images and avatars
  Current Size: ~10GB
  Growth Rate: ~2GB/month
  Business Impact: MEDIUM - User experience impact
  Backup Strategy: Versioning + Intelligent tiering
```

#### Important Buckets (Tier 2) - Limited Data Loss Acceptable
```yaml
distronation-reporting:
  Purpose: Analytics data and business intelligence
  Current Size: ~50GB (estimated)
  Business Impact: MEDIUM - Can be regenerated
  Backup Strategy: Lifecycle policies + Standard-IA backup
  
amplify-* buckets:
  Purpose: Application deployment artifacts
  Current Size: Various
  Business Impact: LOW - Can be rebuilt from source code
  Backup Strategy: Versioning for recent deployments only
```

#### Utility Buckets (Tier 3) - Data Loss Acceptable
```yaml
distronation-backup:
  Purpose: Backup storage for other systems
  Business Impact: LOW - Secondary backup location
  Backup Strategy: Basic lifecycle management
  
CloudFormation/CDK buckets:
  Purpose: Infrastructure deployment artifacts
  Business Impact: LOW - Regenerable from source
  Backup Strategy: Version control integration only
```

### 1.2 Storage Class Strategy

#### Intelligent Tiering Implementation
```json
{
  "Rules": [
    {
      "ID": "AudioFilesLifecycle",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "audio/"
      },
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 90,
          "StorageClass": "GLACIER"
        },
        {
          "Days": 365,
          "StorageClass": "DEEP_ARCHIVE"
        }
      ]
    },
    {
      "ID": "UserUploadsIntelligentTiering",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "uploads/"
      },
      "Transitions": [
        {
          "Days": 0,
          "StorageClass": "INTELLIGENT_TIERING"
        }
      ]
    }
  ]
}
```

## 2. Versioning Configuration

### 2.1 Critical Bucket Versioning

#### Enable Versioning on Critical Buckets
```bash
#!/bin/bash
# enable-s3-versioning.sh
# Enable versioning on critical S3 buckets

CRITICAL_BUCKETS=(
  "distronation-audio"
  "distro-nation-upload" 
  "distronationfm-profile-pictures"
  "distronation-reporting"
)

for bucket in "${CRITICAL_BUCKETS[@]}"; do
  echo "Enabling versioning on bucket: $bucket"
  
  # Enable versioning
  aws s3api put-bucket-versioning \
    --bucket "$bucket" \
    --versioning-configuration Status=Enabled
    
  # Enable MFA delete protection for critical buckets
  if [[ "$bucket" == "distronation-audio" || "$bucket" == "distro-nation-upload" ]]; then
    aws s3api put-bucket-versioning \
      --bucket "$bucket" \
      --versioning-configuration Status=Enabled,MFADelete=Enabled \
      --mfa "arn:aws:iam::<AWS_ACCOUNT_ID>:mfa/your-mfa-device 123456"
  fi
  
  echo "Versioning enabled for $bucket"
done
```

### 2.2 Version Lifecycle Management

#### Automated Version Cleanup
```json
{
  "Rules": [
    {
      "ID": "VersionLifecycleManagement",
      "Status": "Enabled",
      "NoncurrentVersionTransitions": [
        {
          "NoncurrentDays": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "NoncurrentDays": 90,
          "StorageClass": "GLACIER"
        }
      ],
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 365
      },
      "AbortIncompleteMultipartUpload": {
        "DaysAfterInitiation": 7
      }
    }
  ]
}
```

#### Apply Lifecycle Configuration
```bash
# Apply lifecycle configuration to buckets
for bucket in "${CRITICAL_BUCKETS[@]}"; do
  echo "Applying lifecycle configuration to: $bucket"
  
  aws s3api put-bucket-lifecycle-configuration \
    --bucket "$bucket" \
    --lifecycle-configuration file://lifecycle-config.json
    
  echo "Lifecycle configuration applied to $bucket"
done
```

## 3. Cross-Region Replication

### 3.1 Replication Configuration

#### Create Cross-Region Replication Role
```bash
# Create IAM role for cross-region replication
aws iam create-role \
  --role-name S3-CrossRegion-Replication-Role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "s3.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }'

# Attach replication policy
aws iam attach-role-policy \
  --role-name S3-CrossRegion-Replication-Role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSS3ReplicationServiceRolePolicy
```

#### Configure Replication for Critical Buckets
```bash
#!/bin/bash
# setup-cross-region-replication.sh

SOURCE_REGION="<REGION>"
DEST_REGION="us-west-2"
ROLE_ARN="arn:aws:iam::<AWS_ACCOUNT_ID>:role/S3-CrossRegion-Replication-Role"

setup_replication() {
  local source_bucket=$1
  local dest_bucket="${source_bucket}-backup-${DEST_REGION}"
  
  # Create destination bucket
  aws s3api create-bucket \
    --bucket "$dest_bucket" \
    --region "$DEST_REGION" \
    --create-bucket-configuration LocationConstraint="$DEST_REGION"
    
  # Enable versioning on destination bucket
  aws s3api put-bucket-versioning \
    --bucket "$dest_bucket" \
    --versioning-configuration Status=Enabled
    
  # Configure replication
  aws s3api put-bucket-replication \
    --bucket "$source_bucket" \
    --replication-configuration '{
      "Role": "'$ROLE_ARN'",
      "Rules": [
        {
          "ID": "ReplicateEverything",
          "Status": "Enabled",
          "Filter": {},
          "DeleteMarkerReplication": {
            "Status": "Enabled"
          },
          "Destination": {
            "Bucket": "arn:aws:s3:::'$dest_bucket'",
            "StorageClass": "STANDARD_IA",
            "ReplicationTime": {
              "Status": "Enabled",
              "Time": {
                "Minutes": 15
              }
            },
            "Metrics": {
              "Status": "Enabled",
              "EventThreshold": {
                "Minutes": 15
              }
            }
          }
        }
      ]
    }'
    
  echo "Replication configured: $source_bucket -> $dest_bucket"
}

# Set up replication for critical buckets
setup_replication "distronation-audio"
setup_replication "distro-nation-upload"
```

### 3.2 Replication Monitoring

#### CloudWatch Metrics for Replication
```bash
# Create CloudWatch alarm for replication failures
aws cloudwatch put-metric-alarm \
  --alarm-name "S3-Replication-Failure" \
  --alarm-description "Alert when S3 replication fails" \
  --metric-name "ReplicationFailures" \
  --namespace "AWS/S3" \
  --statistic "Sum" \
  --period 300 \
  --threshold 1 \
  --comparison-operator "GreaterThanOrEqualToThreshold" \
  --evaluation-periods 1 \
  --alarm-actions "arn:aws:sns:<REGION>:<AWS_ACCOUNT_ID>:s3-backup-alerts"

# Monitor replication lag
aws cloudwatch put-metric-alarm \
  --alarm-name "S3-Replication-Lag" \
  --alarm-description "Alert when S3 replication lag exceeds threshold" \
  --metric-name "ReplicationLatency" \
  --namespace "AWS/S3" \
  --statistic "Average" \
  --period 900 \
  --threshold 900 \
  --comparison-operator "GreaterThanThreshold" \
  --evaluation-periods 2 \
  --alarm-actions "arn:aws:sns:<REGION>:<AWS_ACCOUNT_ID>:s3-backup-alerts"
```

## 4. Backup and Recovery Procedures

### 4.1 Point-in-Time Recovery

#### Object Version Recovery
```bash
#!/bin/bash
# s3-object-recovery.sh
# Recover specific object versions from S3

recover_object_version() {
  local bucket=$1
  local object_key=$2
  local version_id=$3
  local recovery_location=$4
  
  echo "Recovering object: s3://$bucket/$object_key (version: $version_id)"
  
  # Download specific version
  aws s3api get-object \
    --bucket "$bucket" \
    --key "$object_key" \
    --version-id "$version_id" \
    "$recovery_location"
    
  if [ $? -eq 0 ]; then
    echo "SUCCESS: Object recovered to $recovery_location"
  else
    echo "ERROR: Failed to recover object"
    return 1
  fi
}

# List object versions for recovery
list_object_versions() {
  local bucket=$1
  local prefix=$2
  
  echo "Listing versions for s3://$bucket/$prefix*"
  
  aws s3api list-object-versions \
    --bucket "$bucket" \
    --prefix "$prefix" \
    --query 'Versions[*].{Key:Key,VersionId:VersionId,LastModified:LastModified,Size:Size}' \
    --output table
}

# Example usage:
# list_object_versions "distronation-audio" "tracks/2025/"
# recover_object_version "distronation-audio" "tracks/2025/song.mp3" "abc123version" "/tmp/recovered-song.mp3"
```

#### Bulk Recovery Operations
```bash
#!/bin/bash
# bulk-s3-recovery.sh
# Recover multiple objects to a specific point in time

bulk_recovery() {
  local bucket=$1
  local prefix=$2
  local recovery_time=$3  # ISO 8601 format
  local destination_bucket=$4
  
  echo "Starting bulk recovery for s3://$bucket/$prefix* before $recovery_time"
  
  # Get object versions before the specified time
  aws s3api list-object-versions \
    --bucket "$bucket" \
    --prefix "$prefix" \
    --query "Versions[?LastModified<='$recovery_time'].[Key,VersionId]" \
    --output text | while read key version_id; do
    
    if [ -n "$key" ] && [ -n "$version_id" ]; then
      echo "Recovering: $key (version: $version_id)"
      
      # Copy version to destination bucket
      aws s3api copy-object \
        --copy-source "$bucket/$key?versionId=$version_id" \
        --bucket "$destination_bucket" \
        --key "recovered-$(date +%Y%m%d)/$key"
    fi
  done
  
  echo "Bulk recovery completed"
}

# Example usage:
# bulk_recovery "distronation-audio" "tracks/" "2025-07-25T12:00:00.000Z" "distronation-recovery"
```

### 4.2 Cross-Region Recovery

#### Failover to Replica Region
```bash
#!/bin/bash
# s3-cross-region-failover.sh
# Failover to cross-region replicated buckets

failover_to_replica() {
  local primary_bucket=$1
  local replica_region="us-west-2"
  local replica_bucket="${primary_bucket}-backup-${replica_region}"
  
  echo "Initiating failover from $primary_bucket to $replica_bucket"
  
  # Verify replica bucket accessibility
  aws s3api head-bucket --bucket "$replica_bucket" --region "$replica_region"
  
  if [ $? -eq 0 ]; then
    echo "Replica bucket accessible: $replica_bucket"
    
    # Update application configuration to use replica bucket
    # This would typically involve updating Lambda environment variables,
    # API Gateway configurations, etc.
    
    # Example: Update Lambda function environment variables
    aws lambda update-function-configuration \
      --function-name "your-lambda-function" \
      --environment Variables="{S3_BUCKET=$replica_bucket,S3_REGION=$replica_region}"
      
    echo "Failover completed - applications now using replica bucket"
  else
    echo "ERROR: Replica bucket not accessible"
    return 1
  fi
}

# Failback to primary region
failback_to_primary() {
  local primary_bucket=$1
  local primary_region="<REGION>"
  
  echo "Initiating failback to primary bucket: $primary_bucket"
  
  # Verify primary bucket accessibility
  aws s3api head-bucket --bucket "$primary_bucket" --region "$primary_region"
  
  if [ $? -eq 0 ]; then
    # Update applications back to primary bucket
    aws lambda update-function-configuration \
      --function-name "your-lambda-function" \
      --environment Variables="{S3_BUCKET=$primary_bucket,S3_REGION=$primary_region}"
      
    echo "Failback completed - applications restored to primary bucket"
  else
    echo "ERROR: Primary bucket not yet accessible"
    return 1
  fi
}
```

## 5. Data Integrity and Validation

### 5.1 Automated Integrity Checking

#### S3 Object Integrity Validation
```python
#!/usr/bin/env python3
# s3-integrity-check.py
# Validate S3 object integrity and checksums

import boto3
import hashlib
import json
from datetime import datetime, timedelta

def calculate_s3_etag(file_path, chunk_size=8388608):
    """Calculate S3 ETag for a local file"""
    hash_md5 = hashlib.md5()
    with open(file_path, 'rb') as f:
        for chunk in iter(lambda: f.read(chunk_size), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

def validate_bucket_integrity(bucket_name, prefix="", sample_size=100):
    """Validate object integrity for a sample of objects in bucket"""
    s3 = boto3.client('s3')
    
    print(f"Starting integrity check for bucket: {bucket_name}")
    
    try:
        # List objects in bucket
        response = s3.list_objects_v2(
            Bucket=bucket_name,
            Prefix=prefix,
            MaxKeys=sample_size
        )
        
        if 'Contents' not in response:
            print(f"No objects found in bucket {bucket_name}")
            return True
            
        objects = response['Contents']
        total_objects = len(objects)
        valid_objects = 0
        
        for obj in objects:
            key = obj['Key']
            
            try:
                # Get object metadata
                head_response = s3.head_object(Bucket=bucket_name, Key=key)
                
                # Check if object has integrity metadata
                if 'ChecksumSHA256' in head_response:
                    print(f"✓ Object {key} has integrity checksum")
                    valid_objects += 1
                else:
                    print(f"⚠ Object {key} missing integrity checksum")
                    
            except Exception as e:
                print(f"✗ Error checking object {key}: {str(e)}")
                
        success_rate = (valid_objects / total_objects) * 100
        print(f"Integrity check completed: {success_rate:.1f}% objects validated")
        
        return success_rate > 95  # Consider successful if >95% objects valid
        
    except Exception as e:
        print(f"Error during integrity check: {str(e)}")
        return False

def compare_cross_region_integrity(primary_bucket, replica_bucket):
    """Compare object integrity between primary and replica buckets"""
    s3_primary = boto3.client('s3', region_name='<REGION>')
    s3_replica = boto3.client('s3', region_name='us-west-2')
    
    print(f"Comparing integrity: {primary_bucket} vs {replica_bucket}")
    
    # Get object lists from both buckets
    primary_objects = s3_primary.list_objects_v2(Bucket=primary_bucket)
    replica_objects = s3_replica.list_objects_v2(Bucket=replica_bucket)
    
    primary_keys = {obj['Key']: obj['ETag'] for obj in primary_objects.get('Contents', [])}
    replica_keys = {obj['Key']: obj['ETag'] for obj in replica_objects.get('Contents', [])}
    
    # Find mismatches
    mismatches = []
    missing_in_replica = []
    
    for key, etag in primary_keys.items():
        if key not in replica_keys:
            missing_in_replica.append(key)
        elif replica_keys[key] != etag:
            mismatches.append(key)
    
    print(f"Objects missing in replica: {len(missing_in_replica)}")
    print(f"Objects with mismatched ETags: {len(mismatches)}")
    
    if missing_in_replica:
        print("Missing objects:", missing_in_replica[:10])  # Show first 10
    if mismatches:
        print("Mismatched objects:", mismatches[:10])  # Show first 10
    
    return len(missing_in_replica) == 0 and len(mismatches) == 0

# Weekly integrity check for critical buckets
def weekly_integrity_check():
    critical_buckets = [
        'distronation-audio',
        'distro-nation-upload',
        'distronationfm-profile-pictures'
    ]
    
    results = {}
    overall_success = True
    
    for bucket in critical_buckets:
        print(f"\n--- Checking bucket: {bucket} ---")
        bucket_result = validate_bucket_integrity(bucket)
        results[bucket] = bucket_result
        overall_success = overall_success and bucket_result
    
    # Generate report
    report = {
        'timestamp': datetime.now().isoformat(),
        'overall_success': overall_success,
        'bucket_results': results,
        'next_check': (datetime.now() + timedelta(days=7)).isoformat()
    }
    
    # Save report
    with open(f'/var/log/s3-integrity-{datetime.now().strftime("%Y%m%d")}.json', 'w') as f:
        json.dump(report, f, indent=2)
    
    return overall_success

if __name__ == "__main__":
    success = weekly_integrity_check()
    exit(0 if success else 1)
```

### 5.2 Backup Validation

#### Automated Backup Testing
```bash
#!/bin/bash
# s3-backup-validation.sh
# Validate S3 backup and recovery capabilities

LOG_FILE="/var/log/s3-backup-validation-$(date +%Y%m%d).log"
NOTIFICATION_TOPIC="arn:aws:sns:<REGION>:<AWS_ACCOUNT_ID>:s3-backup-alerts"

echo "Starting S3 backup validation - $(date)" >> $LOG_FILE

validate_versioning() {
  local bucket=$1
  
  echo "Validating versioning for bucket: $bucket" >> $LOG_FILE
  
  # Check if versioning is enabled
  versioning_status=$(aws s3api get-bucket-versioning --bucket "$bucket" --query 'Status' --output text)
  
  if [ "$versioning_status" = "Enabled" ]; then
    echo "✓ Versioning enabled for $bucket" >> $LOG_FILE
    return 0
  else
    echo "✗ Versioning NOT enabled for $bucket" >> $LOG_FILE
    return 1
  fi
}

validate_replication() {
  local bucket=$1
  
  echo "Validating replication for bucket: $bucket" >> $LOG_FILE
  
  # Check replication configuration
  aws s3api get-bucket-replication --bucket "$bucket" > /dev/null 2>&1
  
  if [ $? -eq 0 ]; then
    echo "✓ Cross-region replication configured for $bucket" >> $LOG_FILE
    return 0
  else
    echo "⚠ No replication configured for $bucket" >> $LOG_FILE
    return 1
  fi
}

test_recovery() {
  local bucket=$1
  local test_file="backup-test-$(date +%Y%m%d-%H%M%S).txt"
  
  echo "Testing recovery capability for bucket: $bucket" >> $LOG_FILE
  
  # Create test file
  echo "Backup test file created at $(date)" > "/tmp/$test_file"
  
  # Upload test file
  aws s3 cp "/tmp/$test_file" "s3://$bucket/backup-tests/$test_file"
  
  # Wait a moment for versioning
  sleep 5
  
  # Modify test file
  echo "Modified at $(date)" >> "/tmp/$test_file"
  aws s3 cp "/tmp/$test_file" "s3://$bucket/backup-tests/$test_file"
  
  # List versions
  versions=$(aws s3api list-object-versions \
    --bucket "$bucket" \
    --prefix "backup-tests/$test_file" \
    --query 'Versions[].VersionId' \
    --output text)
  
  version_count=$(echo $versions | wc -w)
  
  if [ $version_count -ge 2 ]; then
    echo "✓ Version recovery test passed for $bucket ($version_count versions)" >> $LOG_FILE
    
    # Cleanup test files
    aws s3 rm "s3://$bucket/backup-tests/$test_file"
    rm "/tmp/$test_file"
    
    return 0
  else
    echo "✗ Version recovery test failed for $bucket" >> $LOG_FILE
    return 1
  fi
}

# Main validation
CRITICAL_BUCKETS=("distronation-audio" "distro-nation-upload" "distronationfm-profile-pictures")
overall_success=true

for bucket in "${CRITICAL_BUCKETS[@]}"; do
  echo "--- Validating bucket: $bucket ---" >> $LOG_FILE
  
  if validate_versioning "$bucket" && test_recovery "$bucket"; then
    echo "✓ All tests passed for $bucket" >> $LOG_FILE
  else
    echo "✗ Some tests failed for $bucket" >> $LOG_FILE
    overall_success=false
  fi
done

# Send notification
if [ "$overall_success" = true ]; then
  aws sns publish \
    --topic-arn "$NOTIFICATION_TOPIC" \
    --message "S3 backup validation PASSED for $(date +%Y-%m-%d)" \
    --subject "S3 Backup Validation Success"
else
  aws sns publish \
    --topic-arn "$NOTIFICATION_TOPIC" \
    --message "S3 backup validation FAILED for $(date +%Y-%m-%d). Check logs at $LOG_FILE" \
    --subject "ALERT: S3 Backup Validation Failure"
fi

echo "S3 backup validation completed - $(date)" >> $LOG_FILE
```

## 6. Cost Optimization

### 6.1 Storage Cost Analysis

#### Current Cost Breakdown
```yaml
Current S3 Costs: $16.61/month
  Standard Storage: $16.31 (709 GB @ $0.023/GB-month)
  PUT Requests: $0.30 (60,019 requests)
  GET Requests: $0.00 (within free tier)
  
Optimization Potential:
  Intelligent Tiering: Save 20-30% on storage costs
  Lifecycle Policies: Save 40-60% on archived data
  Cross-region optimization: Reduce replication costs
```

#### Storage Class Optimization
```bash
#!/bin/bash
# optimize-storage-costs.sh
# Implement cost-optimized storage classes

apply_intelligent_tiering() {
  local bucket=$1
  
  echo "Applying Intelligent Tiering to bucket: $bucket"
  
  # Apply intelligent tiering configuration
  aws s3api put-bucket-intelligent-tiering-configuration \
    --bucket "$bucket" \
    --id "EntireBucketIntelligentTiering" \
    --intelligent-tiering-configuration '{
      "Id": "EntireBucketIntelligentTiering",
      "Status": "Enabled",
      "Filter": {},
      "OptionalFields": ["BucketKeyStatus"]
    }'
    
  echo "Intelligent Tiering applied to $bucket"
}

# Apply to appropriate buckets
TIERING_BUCKETS=("distronation-audio" "distro-nation-upload" "distronation-reporting")

for bucket in "${TIERING_BUCKETS[@]}"; do
  apply_intelligent_tiering "$bucket"
done
```

### 6.2 Lifecycle Cost Management

#### Automated Cost Reporting
```python
#!/usr/bin/env python3
# s3-cost-analysis.py
# Analyze S3 storage costs and optimization opportunities

import boto3
import json
from datetime import datetime, timedelta

def analyze_bucket_costs(bucket_name):
    """Analyze storage costs for a specific bucket"""
    s3 = boto3.client('s3')
    cloudwatch = boto3.client('cloudwatch')
    
    # Get bucket storage metrics
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(days=30)
    
    storage_metrics = cloudwatch.get_metric_statistics(
        Namespace='AWS/S3',
        MetricName='BucketSizeBytes',
        Dimensions=[
            {'Name': 'BucketName', 'Value': bucket_name},
            {'Name': 'StorageType', 'Value': 'StandardStorage'}
        ],
        StartTime=start_time,
        EndTime=end_time,
        Period=86400,  # Daily
        Statistics=['Average']
    )
    
    if storage_metrics['Datapoints']:
        latest_size = storage_metrics['Datapoints'][-1]['Average']
        size_gb = latest_size / (1024**3)
        monthly_cost = size_gb * 0.023  # Standard storage pricing
        
        return {
            'bucket': bucket_name,
            'size_gb': round(size_gb, 2),
            'monthly_cost': round(monthly_cost, 2),
            'storage_class_recommendations': get_storage_recommendations(bucket_name, size_gb)
        }
    
    return None

def get_storage_recommendations(bucket_name, size_gb):
    """Get storage class recommendations based on bucket usage patterns"""
    recommendations = []
    
    # Analyze access patterns (simplified)
    if 'audio' in bucket_name.lower():
        recommendations.append({
            'strategy': 'Glacier transition after 90 days',
            'estimated_savings': '60-70%',
            'description': 'Archive older audio files to Glacier'
        })
    
    if 'upload' in bucket_name.lower():
        recommendations.append({
            'strategy': 'Intelligent Tiering',
            'estimated_savings': '20-30%',
            'description': 'Automatically optimize based on access patterns'
        })
    
    if size_gb > 100:
        recommendations.append({
            'strategy': 'Standard-IA after 30 days',
            'estimated_savings': '40-50%',
            'description': 'Move infrequently accessed data to Standard-IA'
        })
    
    return recommendations

def generate_cost_report():
    """Generate comprehensive S3 cost analysis report"""
    s3 = boto3.client('s3')
    
    # Get all buckets
    buckets = s3.list_buckets()['Buckets']
    
    report = {
        'generated_at': datetime.now().isoformat(),
        'total_buckets': len(buckets),
        'bucket_analysis': [],
        'optimization_summary': {
            'total_monthly_cost': 0,
            'potential_savings': 0,
            'optimization_opportunities': []
        }
    }
    
    for bucket in buckets:
        bucket_name = bucket['Name']
        analysis = analyze_bucket_costs(bucket_name)
        
        if analysis:
            report['bucket_analysis'].append(analysis)
            report['optimization_summary']['total_monthly_cost'] += analysis['monthly_cost']
    
    # Calculate potential savings
    total_cost = report['optimization_summary']['total_monthly_cost']
    potential_savings = total_cost * 0.25  # Conservative 25% savings estimate
    
    report['optimization_summary']['potential_savings'] = round(potential_savings, 2)
    report['optimization_summary']['optimization_opportunities'] = [
        'Implement Intelligent Tiering on large buckets',
        'Archive old files to Glacier storage class',
        'Set up lifecycle policies for automated transitions',
        'Review and optimize cross-region replication'
    ]
    
    # Save report
    with open(f'/var/log/s3-cost-analysis-{datetime.now().strftime("%Y%m%d")}.json', 'w') as f:
        json.dump(report, f, indent=2)
    
    return report

if __name__ == "__main__":
    report = generate_cost_report()
    print(f"S3 Cost Analysis Report Generated")
    print(f"Total Monthly Cost: ${report['optimization_summary']['total_monthly_cost']}")
    print(f"Potential Savings: ${report['optimization_summary']['potential_savings']}")
```

## 7. Monitoring and Alerting

### 7.1 CloudWatch Monitoring

#### S3 Backup Health Monitoring
```bash
# Create comprehensive S3 monitoring alarms
aws cloudwatch put-metric-alarm \
  --alarm-name "S3-Backup-Storage-Growth" \
  --alarm-description "Alert when backup storage grows unexpectedly" \
  --metric-name "BucketSizeBytes" \
  --namespace "AWS/S3" \
  --statistic "Average" \
  --period 86400 \
  --threshold 1073741824000 \
  --comparison-operator "GreaterThanThreshold" \
  --evaluation-periods 1 \
  --dimensions Name=BucketName,Value=distronation-audio Name=StorageType,Value=StandardStorage \
  --alarm-actions "arn:aws:sns:<REGION>:<AWS_ACCOUNT_ID>:s3-backup-alerts"

# Monitor replication failures
aws cloudwatch put-metric-alarm \
  --alarm-name "S3-Replication-Failures" \
  --alarm-description "Alert when cross-region replication fails" \
  --metric-name "ReplicationFailures" \
  --namespace "AWS/S3" \
  --statistic "Sum" \
  --period 300 \
  --threshold 1 \
  --comparison-operator "GreaterThanOrEqualToThreshold" \
  --evaluation-periods 1 \
  --alarm-actions "arn:aws:sns:<REGION>:<AWS_ACCOUNT_ID>:s3-backup-alerts"
```

### 7.2 Custom Metrics and Dashboards

#### S3 Backup Dashboard Configuration
```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/S3", "BucketSizeBytes", "BucketName", "distronation-audio", "StorageType", "StandardStorage"],
          ["...", "distro-nation-upload", ".", "."],
          ["...", "distronationfm-profile-pictures", ".", "."]
        ],
        "period": 86400,
        "stat": "Average",
        "region": "<REGION>",
        "title": "Critical Bucket Storage Growth",
        "yAxis": {
          "left": {
            "min": 0
          }
        }
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/S3", "ReplicationLatency", "SourceBucket", "distronation-audio"],
          ["...", "distro-nation-upload"]
        ],
        "period": 300,
        "stat": "Average",
        "region": "<REGION>",
        "title": "Cross-Region Replication Latency"
      }
    }
  ]
}
```

## 8. Implementation Timeline

### Phase 1: Critical Infrastructure (Week 1)
```yaml
✅ Document current S3 backup strategies
⏳ Enable versioning on critical buckets
⏳ Configure lifecycle policies for cost optimization
⏳ Set up basic monitoring and alerting
```

### Phase 2: Cross-Region Protection (Week 2)
```yaml
⏳ Implement cross-region replication for critical buckets
⏳ Create replication monitoring and alerting
⏳ Test cross-region failover procedures
⏳ Document recovery procedures
```

### Phase 3: Automation and Testing (Week 3-4)
```yaml
⏳ Implement automated backup validation
⏳ Create integrity checking scripts
⏳ Set up cost monitoring and optimization
⏳ Establish regular testing schedule
```

## Next Steps

### Immediate Actions
1. ✅ Complete S3 backup strategy documentation
2. ⏳ Implement versioning on critical buckets
3. ⏳ Set up cross-region replication
4. ⏳ Configure monitoring and alerting

### Integration with Empire Standards
1. ⏳ Align with Empire backup retention policies
2. ⏳ Integrate with Empire disaster recovery procedures
3. ⏳ Standardize monitoring and reporting
4. ⏳ Implement Empire security and compliance requirements

---

**Document Version**: 1.0  
**Last Updated**: July 25, 2025  
**Next Review**: October 25, 2025  
**Owner**: Adrian Green, Head of Engineering  
**Status**: Phase 1 Implementation

*This document contains critical backup and recovery procedures for S3 storage. All team members should be familiar with these procedures.*