# JitsuFlow Makefile - 開発コマンド自動化
# ブラジリアン柔術トレーニング＆道場予約アプリ

.PHONY: help init dev build test clean deploy-workers deploy-flutter lint format

# Default target
help:
	@echo "🥋 JitsuFlow Development Commands"
	@echo ""
	@echo "📱 Flutter Commands:"
	@echo "  make dev           - Start Flutter development server"
	@echo "  make build         - Build Flutter app for production"
	@echo "  make test          - Run Flutter tests"
	@echo "  make lint          - Run Flutter linter"
	@echo "  make format        - Format Dart code"
	@echo ""
	@echo "☁️  Cloudflare Workers Commands:"
	@echo "  make workers-dev   - Start Workers development server"
	@echo "  make workers-deploy - Deploy Workers to production"
	@echo "  make db-migrate    - Run database migrations"
	@echo ""
	@echo "🔧 Development Setup:"
	@echo "  make init          - Initialize project dependencies"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make reset         - Reset development environment"
	@echo "  make setup-fastlane - Install and setup fastlane"
	@echo ""
	@echo "🚀 Deployment:"
	@echo "  make deploy        - Deploy entire application"
	@echo "  make staging       - Deploy to staging environment"
	@echo ""
	@echo "📱 App Store:"
	@echo "  make ios-metadata  - Upload iOS metadata to App Store Connect"
	@echo "  make ios-beta      - Build and upload to TestFlight"
	@echo "  make ios-release   - Complete App Store submission"
	@echo "  make ios-create    - Create app on App Store Connect"

# Initialize project
init:
	@echo "🔄 Initializing JitsuFlow development environment..."
	flutter pub get
	cd . && npm install
	@echo "✅ Project initialized successfully!"

# Flutter development
dev:
	@echo "🚀 Starting Flutter development server..."
	flutter run -d chrome --web-port 3000

# Flutter build
build:
	@echo "🏗️  Building Flutter app for production..."
	flutter build web --release
	@echo "✅ Build completed!"

# Flutter tests
test:
	@echo "🧪 Running Flutter tests..."
	flutter test
	@echo "✅ Tests completed!"

# Flutter linting
lint:
	@echo "🔍 Running Flutter linter..."
	flutter analyze
	@echo "✅ Linting completed!"

# Format Dart code
format:
	@echo "🎨 Formatting Dart code..."
	flutter format lib/
	@echo "✅ Code formatted!"

# Cloudflare Workers development
workers-dev:
	@echo "☁️  Starting Cloudflare Workers development server..."
	cd . && npm run dev

# Deploy Workers
workers-deploy:
	@echo "🚀 Deploying Cloudflare Workers..."
	cd . && npm run deploy
	@echo "✅ Workers deployed!"

# Database migration
db-migrate:
	@echo "🗄️  Running database migrations..."
	cd . && wrangler d1 execute jitsuflow_db --file=schema.sql
	@echo "✅ Database migrated!"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	flutter clean
	rm -rf build/
	rm -rf node_modules/
	@echo "✅ Cleaned!"

# Reset development environment
reset: clean init
	@echo "🔄 Development environment reset!"

# Deploy to staging
staging:
	@echo "🚀 Deploying to staging environment..."
	flutter build web --release --dart-define=ENVIRONMENT=staging
	cd . && wrangler deploy --env staging
	@echo "✅ Staging deployment completed!"

# Deploy to production
deploy:
	@echo "🚀 Deploying to production..."
	make test
	make lint
	flutter build web --release --dart-define=ENVIRONMENT=production
	cd . && wrangler deploy --env production
	@echo "✅ Production deployment completed!"

# Development server with hot reload
dev-full:
	@echo "🔥 Starting full development environment..."
	@echo "Starting Workers dev server..."
	cd . && npm run dev &
	@echo "Starting Flutter dev server..."
	flutter run -d chrome --web-port 3000

# Install dependencies
deps:
	@echo "📦 Installing dependencies..."
	flutter pub get
	cd . && npm install
	@echo "✅ Dependencies installed!"

# Check project health
health:
	@echo "🩺 Checking project health..."
	flutter doctor
	cd . && npm audit
	@echo "✅ Health check completed!"

# Generate JSON serialization code
generate:
	@echo "🔧 Generating JSON serialization code..."
	flutter packages pub run build_runner build
	@echo "✅ Code generation completed!"

# Watch and generate code
watch:
	@echo "👀 Watching for changes and generating code..."
	flutter packages pub run build_runner watch

# Setup Cloudflare resources
setup-cloudflare:
	@echo "☁️  Setting up Cloudflare resources..."
	./scripts/setup-cloudflare.sh
	@echo "✅ Cloudflare setup completed!"

# Deploy to staging
deploy-staging:
	@echo "🚀 Deploying to staging..."
	./scripts/deploy.sh staging

# Deploy to production
deploy-prod:
	@echo "🚀 Deploying to production..."
	./scripts/deploy.sh production

# Run E2E tests
e2e:
	@echo "🧪 Running E2E tests..."
	npm run test:e2e
	@echo "✅ E2E tests completed!"

# Run E2E tests with UI
e2e-ui:
	@echo "🧪 Running E2E tests with UI..."
	npm run test:e2e:ui

# Setup environment
setup-env:
	@echo "🔧 Setting up environment..."
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✅ Created .env file. Please update it with your values."; \
	else \
		echo "✅ .env file already exists."; \
	fi

# Full setup
setup: setup-env init setup-cloudflare
	@echo "✅ Full setup completed!"

# iOS App Store Commands (requires fastlane)
ios-create:
	@echo "📱 Creating app on App Store Connect..."
	export PATH="/opt/homebrew/lib/ruby/gems/3.2.0/bin:$$PATH" && fastlane ios create_app
	@echo "✅ App created on App Store Connect!"

ios-metadata:
	@echo "📱 Uploading iOS metadata and screenshots..."
	export PATH="/opt/homebrew/lib/ruby/gems/3.2.0/bin:$$PATH" && fastlane ios metadata_only
	@echo "✅ iOS metadata uploaded!"

ios-beta:
	@echo "📱 Building and uploading to TestFlight..."
	export PATH="/opt/homebrew/lib/ruby/gems/3.2.0/bin:$$PATH" && fastlane ios beta
	@echo "✅ Uploaded to TestFlight!"

ios-release:
	@echo "📱 Complete App Store submission..."
	export PATH="/opt/homebrew/lib/ruby/gems/3.2.0/bin:$$PATH" && fastlane ios release
	@echo "✅ App submitted for review!"

# Setup fastlane
setup-fastlane:
	@echo "🔧 Setting up fastlane..."
	gem install fastlane
	@echo "✅ Fastlane installed!"
	@echo ""
	@echo "⚠️  Next steps:"
	@echo "1. Create App Store Connect API Key (see fastlane/API_KEY_SETUP.md)"
	@echo "2. Set environment variables:"
	@echo "   export ASC_KEY_ID=\"YOUR_KEY_ID\""
	@echo "   export ASC_ISSUER_ID=\"YOUR_ISSUER_ID\""
	@echo "   export ASC_KEY_PATH=\"/Users/yuki/jitsuflow/fastlane/authkey/AuthKey_XXXXXXXXX.p8\""
	@echo "3. Run: make ios-metadata"