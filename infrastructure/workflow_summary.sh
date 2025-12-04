#!/bin/bash

# The $GITHUB_STEP_SUMMARY variable is automatically available 
# to this script when run by GitHub Actions.

echo "## Deployment Successful!" >> $GITHUB_STEP_SUMMARY
echo "Here are your infrastructure details:" >> $GITHUB_STEP_SUMMARY
echo "" >> $GITHUB_STEP_SUMMARY
BOT_ID=$(terraform output -raw bot_id)
BOT_ALIAS_ID=$(terraform output -raw bot_alias_id)
echo '```terraform' >> $GITHUB_STEP_SUMMARY
echo "bot_id = $BOT_ID" >> $GITHUB_STEP_SUMMARY
echo "bot_alias_id = $BOT_ALIAS_ID" >> $GITHUB_STEP_SUMMARY
echo '```' >> $GITHUB_STEP_SUMMARY
URL=$(terraform output -raw https_url)
echo "**[Click to Open Chatbot]($URL)**" >> $GITHUB_STEP_SUMMARY
