#!/bin/bash

echo "Setting up custom domains for JitsuFlow..."

# Add custom domains to Cloudflare Pages
echo "Adding jitsuflow.app to Pages project..."
npx wrangler pages domains add jitsuflow.app --project-name=jitsuflow

echo "Adding www.jitsuflow.app to Pages project..."
npx wrangler pages domains add www.jitsuflow.app --project-name=jitsuflow

# List domains to verify
echo -e "\nVerifying domains..."
npx wrangler pages domains list --project-name=jitsuflow

echo -e "\nCustom domain setup complete!"
echo "Note: It may take a few minutes for the domains to be fully activated."