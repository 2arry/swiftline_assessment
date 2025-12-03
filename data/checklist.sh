# Copyright (c) 2025, Assessment: SolutionsEngineer-candidate-larry

# terraform destroy -auto-approve
# terraform apply -auto-approve
# aws --profile larry lexv2-runtime recognize-text --region us-east-1 --bot-id [OUTPUT] --bot-alias-id [OUTPUT] --locale-id en_US --session-id "TestUser1" --text "SWL-2024-AIR-001234"
# aws --profile larry lexv2-runtime recognize-text --region us-east-1 --bot-id [OUTPUT] --bot-alias-id [OUTPUT] --locale-id en_US --session-id "TestUser1" --text "SWL-2024-AIR-001234"

# This would return the response message from Lex V2 bot
# aws --profile larry lexv2-runtime recognize-text \
#     --region us-east-1 \
#     --bot-id [OUTPUT] \
#     --bot-alias-id [OUTPUT] \
#     --locale-id en_US \
#     --session-id "TestUser1" \
#     --text "SWL-2024-AIR-001234" \
#     --query 'messages[0].content' \
#     --output text

# aws --profile larry lexv2-runtime recognize-text --region us-east-1 --bot-id [OUTPUT] --bot-alias-id [OUTPUT] --locale-id en_US --session-id "TestUser1" --text "SWL-2024-AIR-001234" --query 'messages[0].content' --output text

# aws --profile larry lexv2-runtime recognize-text --region us-east-1 --bot-id [OUTPUT] --bot-alias-id [OUTPUT] --locale-id en_US --session-id "TestUser1" --text "Where is my order"

# To delete CloudWatch Log Group for Lambda function
# MSYS_NO_PATHCONV=1 aws --profile larry logs delete-log-group --region us-east-1 --log-group-name /aws/lambda/SwiftLineOrderCheck

# Initialise, add, commit, and push to GitHub repository
# git init && git add . && git commit -m "Initial commit of my project" && git remote add origin https://github.com/2arry/swiftline_assessment.git && git pull origin main --allow-unrelated-histories && git push -u origin main

# To remove git history and start afresh
# rm -rf .git

# To push changes to GitHub
# git add -A && git commit -m "OIDC Test" && git push

# To initialize Terraform with migration of state
# AWS_PROFILE=larry terraform init -migrate-state
