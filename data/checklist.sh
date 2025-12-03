# Copyright (c) 2025, Assessment: SolutionsEngineer-LarryAdah

# terraform destroy -auto-approve
# terraform apply -auto-approve
# aws --profile larry lexv2-runtime recognize-text --region us-east-1 --bot-id [OUTPUT] --bot-alias-id [OUTPUT] --locale-id en_US --session-id "TestUser1" --text "SWL-2024-AIR-001234"
# aws --profile larry lexv2-runtime recognize-text --region us-east-1 --bot-id [OUTPUT] --bot-alias-id [OUTPUT] --locale-id en_US --session-id "TestUser1" --text "Where is my order"

# Initialise, add, commit, and push to GitHub repository
git init && git add . && git commit -m "Initial commit of my project" && git remote add origin https://github.com/2arry/swiftline_assessment.git && git pull origin main --allow-unrelated-histories && git push -u origin main
