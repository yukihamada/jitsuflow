#!/bin/bash

# JitsuFlow Cloudflare Setup Script
# This script creates all necessary Cloudflare resources

set -e

echo "🚀 JitsuFlow Cloudflare Setup"
echo "=============================="

# Check if required environment variables are set
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found"
    echo "Please copy .env.example to .env and fill in your values"
    exit 1
fi

# Load environment variables
source .env

# Check required variables
required_vars=("CLOUDFLARE_ACCOUNT_ID" "CLOUDFLARE_API_TOKEN")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Error: $var is not set in .env"
        exit 1
    fi
done

echo "✅ Environment variables loaded"

# Function to check if wrangler is installed
check_wrangler() {
    if ! command -v wrangler &> /dev/null; then
        echo "❌ Wrangler CLI not found. Installing..."
        npm install -g wrangler
    fi
    echo "✅ Wrangler CLI is installed"
}

# Function to create D1 database
create_d1_database() {
    echo ""
    echo "📊 Creating D1 Database..."
    
    # Check if database already exists
    existing_db=$(wrangler d1 list --json | jq -r ".[] | select(.name==\"$D1_DATABASE_NAME\") | .uuid" || echo "")
    
    if [ -n "$existing_db" ]; then
        echo "✅ D1 database already exists: $existing_db"
        D1_DATABASE_ID=$existing_db
    else
        # Create new database
        output=$(wrangler d1 create "$D1_DATABASE_NAME" --json)
        D1_DATABASE_ID=$(echo "$output" | jq -r '.uuid')
        echo "✅ D1 database created: $D1_DATABASE_ID"
    fi
    
    # Update wrangler.toml with database ID
    sed -i.bak "s/database_id = \"placeholder\"/database_id = \"$D1_DATABASE_ID\"/" wrangler.toml
    
    # Run migrations
    echo "🔄 Running database migrations..."
    wrangler d1 execute "$D1_DATABASE_NAME" --file=schema.sql
    echo "✅ Database migrations completed"
}

# Function to create R2 bucket
create_r2_bucket() {
    echo ""
    echo "🪣 Creating R2 Bucket..."
    
    # Check if bucket already exists
    existing_bucket=$(wrangler r2 bucket list --json | jq -r ".[] | select(.name==\"$R2_BUCKET_NAME\") | .name" || echo "")
    
    if [ -n "$existing_bucket" ]; then
        echo "✅ R2 bucket already exists: $existing_bucket"
    else
        # Create new bucket
        wrangler r2 bucket create "$R2_BUCKET_NAME"
        echo "✅ R2 bucket created: $R2_BUCKET_NAME"
    fi
    
    # Set CORS policy
    echo "🔧 Setting R2 CORS policy..."
    cat > r2-cors.json << EOF
[
  {
    "AllowedOrigins": ["http://localhost:3000", "https://jitsuflow.app"],
    "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }
]
EOF
    
    wrangler r2 bucket cors put "$R2_BUCKET_NAME" --rules r2-cors.json
    rm r2-cors.json
    echo "✅ R2 CORS policy set"
}

# Function to create KV namespace
create_kv_namespace() {
    echo ""
    echo "🗄️  Creating KV Namespace..."
    
    # Check if namespace already exists
    existing_kv=$(wrangler kv:namespace list --json | jq -r ".[] | select(.title==\"$KV_NAMESPACE_NAME\") | .id" || echo "")
    
    if [ -n "$existing_kv" ]; then
        echo "✅ KV namespace already exists: $existing_kv"
        KV_NAMESPACE_ID=$existing_kv
    else
        # Create new namespace
        output=$(wrangler kv:namespace create "SESSIONS" --preview false)
        KV_NAMESPACE_ID=$(echo "$output" | grep -oE '[a-f0-9]{32}')
        echo "✅ KV namespace created: $KV_NAMESPACE_ID"
    fi
    
    # Update wrangler.toml with namespace ID
    sed -i.bak "s/id = \"placeholder\"/id = \"$KV_NAMESPACE_ID\"/" wrangler.toml
}

# Function to create Cloudflare Pages project
create_pages_project() {
    echo ""
    echo "📄 Creating Cloudflare Pages project..."
    
    # Check if project already exists
    existing_project=$(wrangler pages project list --json | jq -r ".[] | select(.name==\"jitsuflow\") | .name" || echo "")
    
    if [ -n "$existing_project" ]; then
        echo "✅ Pages project already exists: jitsuflow"
    else
        # Create new Pages project
        wrangler pages project create jitsuflow --production-branch main
        echo "✅ Pages project created: jitsuflow"
    fi
    
    # Create staging project
    existing_staging=$(wrangler pages project list --json | jq -r ".[] | select(.name==\"jitsuflow-staging\") | .name" || echo "")
    
    if [ -n "$existing_staging" ]; then
        echo "✅ Staging Pages project already exists: jitsuflow-staging"
    else
        wrangler pages project create jitsuflow-staging --production-branch develop
        echo "✅ Staging Pages project created: jitsuflow-staging"
    fi
}

# Function to update .env with created resource IDs
update_env_file() {
    echo ""
    echo "📝 Updating .env file with resource IDs..."
    
    # Update D1 database ID
    if [ -n "$D1_DATABASE_ID" ]; then
        sed -i.bak "s/D1_DATABASE_ID=.*/D1_DATABASE_ID=$D1_DATABASE_ID/" .env
    fi
    
    # Update KV namespace ID
    if [ -n "$KV_NAMESPACE_ID" ]; then
        sed -i.bak "s/KV_NAMESPACE_ID=.*/KV_NAMESPACE_ID=$KV_NAMESPACE_ID/" .env
    fi
    
    echo "✅ .env file updated"
}

# Function to setup secrets
setup_secrets() {
    echo ""
    echo "🔐 Setting up Cloudflare Workers secrets..."
    
    # List of secrets to set
    secrets=(
        "JWT_SECRET"
        "STRIPE_SECRET_KEY"
        "STRIPE_WEBHOOK_SECRET"
        "OPENAI_API_KEY"
        "GROQ_API_KEY"
        "RESEND_API_KEY"
    )
    
    for secret in "${secrets[@]}"; do
        if [ -n "${!secret}" ] && [ "${!secret}" != "your_${secret,,}_here" ]; then
            echo "Setting $secret..."
            echo "${!secret}" | wrangler secret put "$secret" --name "$WORKER_NAME"
        else
            echo "⚠️  Skipping $secret (not set or using placeholder value)"
        fi
    done
    
    echo "✅ Secrets configuration completed"
}

# Main execution
main() {
    echo ""
    echo "Starting Cloudflare setup..."
    echo ""
    
    check_wrangler
    create_d1_database
    create_r2_bucket
    create_kv_namespace
    create_pages_project
    update_env_file
    setup_secrets
    
    echo ""
    echo "✅ Cloudflare setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Review and update wrangler.toml with the generated IDs"
    echo "2. Deploy Workers: npm run deploy"
    echo "3. Deploy Pages: npm run deploy:pages"
    echo ""
    echo "Resource Summary:"
    echo "- D1 Database: $D1_DATABASE_NAME (ID: $D1_DATABASE_ID)"
    echo "- R2 Bucket: $R2_BUCKET_NAME"
    echo "- KV Namespace: $KV_NAMESPACE_NAME (ID: $KV_NAMESPACE_ID)"
    echo "- Pages Projects: jitsuflow, jitsuflow-staging"
}

# Run main function
main