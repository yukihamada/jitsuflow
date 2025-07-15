#!/bin/bash

# JitsuFlow Deployment Script
# Handles deployment to staging or production

set -e

# Default environment
ENV=${1:-staging}

echo "🚀 JitsuFlow Deployment Script"
echo "=============================="
echo "Environment: $ENV"
echo ""

# Check environment
if [ "$ENV" != "staging" ] && [ "$ENV" != "production" ]; then
    echo "❌ Error: Invalid environment. Use 'staging' or 'production'"
    exit 1
fi

# Load environment variables
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found"
    exit 1
fi

source .env

# Function to run tests
run_tests() {
    echo "🧪 Running tests..."
    
    # Flutter tests
    echo "Running Flutter tests..."
    flutter test
    
    # API tests
    echo "Running API tests..."
    npm test
    
    echo "✅ All tests passed"
}

# Function to build Flutter app
build_flutter() {
    echo ""
    echo "🏗️  Building Flutter app for $ENV..."
    
    if [ "$ENV" = "production" ]; then
        flutter build web --release --dart-define=ENVIRONMENT=production
    else
        flutter build web --release --dart-define=ENVIRONMENT=staging
    fi
    
    echo "✅ Flutter build completed"
}

# Function to deploy Workers
deploy_workers() {
    echo ""
    echo "☁️  Deploying Workers to $ENV..."
    
    if [ "$ENV" = "production" ]; then
        wrangler deploy --env production
    else
        wrangler deploy --env staging
    fi
    
    echo "✅ Workers deployed"
}

# Function to deploy Pages
deploy_pages() {
    echo ""
    echo "📄 Deploying Pages to $ENV..."
    
    if [ "$ENV" = "production" ]; then
        wrangler pages deploy build/web --project-name=jitsuflow
    else
        wrangler pages deploy build/web --project-name=jitsuflow-staging
    fi
    
    echo "✅ Pages deployed"
}

# Function to run database migrations
run_migrations() {
    echo ""
    echo "🗄️  Running database migrations..."
    
    if [ "$ENV" = "production" ]; then
        wrangler d1 execute "$D1_DATABASE_NAME" --file=schema.sql --env production
    else
        wrangler d1 execute "$D1_DATABASE_NAME" --file=schema.sql --env staging
    fi
    
    echo "✅ Migrations completed"
}

# Function to notify deployment
notify_deployment() {
    echo ""
    echo "📢 Sending deployment notification..."
    
    if [ -n "$GOOGLE_CHAT_WEBHOOK_URL" ] && [ "$GOOGLE_CHAT_WEBHOOK_URL" != "your_google_chat_webhook_url" ]; then
        message="🚀 JitsuFlow deployed to $ENV environment\n\n"
        message+="• Commit: $(git rev-parse --short HEAD)\n"
        message+="• Branch: $(git branch --show-current)\n"
        message+="• Time: $(date '+%Y-%m-%d %H:%M:%S')\n"
        message+="• Deployed by: $(git config user.name)"
        
        curl -X POST "$GOOGLE_CHAT_WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"text\": \"$message\"}" \
            --silent > /dev/null
        
        echo "✅ Notification sent"
    else
        echo "⚠️  Google Chat webhook not configured"
    fi
}

# Function to verify deployment
verify_deployment() {
    echo ""
    echo "🔍 Verifying deployment..."
    
    # Check Workers health
    if [ "$ENV" = "production" ]; then
        api_url="https://jitsuflow.app/api/health"
    else
        api_url="https://staging.jitsuflow.app/api/health"
    fi
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$api_url")
    
    if [ "$response" = "200" ]; then
        echo "✅ API health check passed"
    else
        echo "❌ API health check failed (HTTP $response)"
        exit 1
    fi
}

# Main deployment flow
main() {
    echo "Starting deployment to $ENV..."
    echo ""
    
    # Only run tests for production deployments
    if [ "$ENV" = "production" ]; then
        run_tests
    fi
    
    build_flutter
    deploy_workers
    run_migrations
    deploy_pages
    verify_deployment
    notify_deployment
    
    echo ""
    echo "✅ Deployment completed successfully!"
    echo ""
    echo "Access your application at:"
    if [ "$ENV" = "production" ]; then
        echo "🌐 https://jitsuflow.app"
    else
        echo "🌐 https://staging.jitsuflow.app"
    fi
}

# Check for required tools
check_requirements() {
    echo "Checking requirements..."
    
    required_tools=("flutter" "wrangler" "npm" "git" "curl" "jq")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo "❌ Error: $tool is required but not installed"
            exit 1
        fi
    done
    
    echo "✅ All requirements met"
}

# Run deployment
check_requirements
main