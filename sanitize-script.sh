#!/bin/bash
# Find and replace sensitive data in all markdown files
find . -type f -name "*.md" -print0 | xargs -0 sed -i '' 's/<AWS_ACCOUNT_ID>/<AWS_ACCOUNT_ID>/g'
find . -type f -name "*.md" -print0 | xargs -0 sed -i '' 's/<API_GATEWAY_ID_2>/<API_GATEWAY_ID_2>/g'
find . -type f -name "*.md" -print0 | xargs -0 sed -i '' 's/<API_GATEWAY_ID_1>/<API_GATEWAY_ID_1>/g'
exit 0