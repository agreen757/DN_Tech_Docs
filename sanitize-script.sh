#!/bin/bash
# Find and replace sensitive data in all markdown files
find . -type f -name "*.md" -print0 | xargs -0 sed -i '' 's/867653852961/<AWS_ACCOUNT_ID>/g'
find . -type f -name "*.md" -print0 | xargs -0 sed -i '' 's/cjed05n28l/<API_GATEWAY_ID_2>/g'
find . -type f -name "*.md" -print0 | xargs -0 sed -i '' 's/hmuujzief2/<API_GATEWAY_ID_1>/g'
exit 0