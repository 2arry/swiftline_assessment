#!/bin/bash

# The $GITHUB_STEP_SUMMARY variable is automatically available 
# to this script when run by GitHub Actions.

echo "## Deployment Successful!" >> $GITHUB_STEP_SUMMARY
echo "Here are your infrastructure details:" >> $GITHUB_STEP_SUMMARY
echo "" >> $GITHUB_STEP_SUMMARY
echo '```terraform' >> $GITHUB_STEP_SUMMARY
terraform output >> $GITHUB_STEP_SUMMARY
echo '```' >> $GITHUB_STEP_SUMMARY
