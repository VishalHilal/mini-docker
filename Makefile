.PHONY: help build run test clean docker-start docker-stop docker-restart docker-logs docker-test docker-status docker-cleanup setup setup-basic setup-cache setup-database setup-proxy setup-monitoring setup-tracing setup-full

# Default target
help:
	@echo "Mini-Docker Makefile"
	@echo ""
	@echo "Build Targets:"
	@echo "  build          Build the Go binaries"
	@echo "  run-engine     Run the engine server"
	@echo "  run-cli        Run the CLI client"
	@echo "  test           Run tests"
	@echo "  clean          Clean build artifacts"
	@echo ""
	@echo "Docker Targets:"
	@echo "  docker-start   Start basic Docker services"
	@echo "  docker-stop    Stop Docker services"
	@echo "  docker-restart Restart Docker services"
	@echo "  docker-logs    Show Docker logs"
	@echo "  docker-test    Test Docker setup"
	@echo "  docker-status  Show Docker status"
	@echo "  docker-cleanup Clean Docker resources"
	@echo ""
	@echo "Setup Targets:"
	@echo "  setup-basic    Setup basic engine only"
	@echo "  setup-cache    Setup with Redis cache"
	@echo "  setup-database Setup with PostgreSQL"
	@echo "  setup-proxy    Setup with Nginx proxy"
	@echo "  setup-monitoring Setup with monitoring"
	@echo "  setup-tracing  Setup with Jaeger tracing"
	@echo "  setup-full     Setup complete stack"
	@echo ""
	@echo "Quick Examples:"
	@echo "  make setup-full      # Complete setup"
	@echo "  make docker-start    # Start basic services"
	@echo "  make docker-logs     # View logs"

# Build targets
build:
	@echo "Building mini-docker binaries..."
	go build -o bin/engine ./cmd/engine/main.go
	go build -o bin/cli ./cmd/docker/main.go
	@echo "Build completed!"

run-engine:
	@echo "Starting mini-docker engine..."
	go run ./cmd/engine/main.go

run-cli:
	@echo "Running mini-docker CLI..."
	go run ./cmd/docker/main.go

# Test targets
test:
	@echo "Running tests..."
	go test ./...

clean:
	@echo "Cleaning build artifacts..."
	rm -rf bin/
	go clean
	@echo "Clean completed!"

# Docker targets
docker-start:
	@echo "Starting Docker services..."
	docker-compose up -d engine

docker-stop:
	@echo "Stopping Docker services..."
	docker-compose down

docker-restart: docker-stop docker-start

docker-logs:
	docker-compose logs -f engine

docker-test:
	@echo "Testing Docker setup..."
	docker-compose --profile testing up -d
	docker-compose exec cli go run ./cmd/docker/main.go images
	docker-compose exec cli go run ./cmd/docker/main.go ps

docker-status:
	@echo "Docker service status:"
	docker-compose ps

docker-cleanup:
	@echo "Cleaning Docker resources..."
	docker-compose down -v --remove-orphans
	docker system prune -f

# Setup targets
setup-basic:
	@echo "Setting up basic mini-docker..."
	./scripts/setup.sh setup basic

setup-cache:
	@echo "Setting up mini-docker with cache..."
	./scripts/setup.sh setup cache

setup-database:
	@echo "Setting up mini-docker with database..."
	./scripts/setup.sh setup database

setup-proxy:
	@echo "Setting up mini-docker with proxy..."
	./scripts/setup.sh setup proxy

setup-monitoring:
	@echo "Setting up mini-docker with monitoring..."
	./scripts/setup.sh setup monitoring

setup-tracing:
	@echo "Setting up mini-docker with tracing..."
	./scripts/setup.sh setup tracing

setup-full:
	@echo "Setting up complete mini-docker stack..."
	./scripts/setup.sh setup full

# Development targets
dev-start:
	@echo "Starting development environment..."
	docker-compose --profile dev up -d

dev-logs:
	docker-compose logs -f dev

# Quick start
quick-start: build docker-start
	@echo "Quick start completed!"
	@echo "Engine is running on http://localhost:8080"
	@echo "Use 'make docker-logs' to view logs"

# Advanced commands
show-urls:
	@echo "Service URLs:"
	@echo "• Engine API:      http://localhost:8080"
	@if docker-compose ps nginx | grep -q "Up"; then echo "• Web Interface:  http://localhost"; fi
	@if docker-compose ps prometheus | grep -q "Up"; then echo "• Prometheus:     http://localhost:9090"; fi
	@if docker-compose ps grafana | grep -q "Up"; then echo "• Grafana:        http://localhost:3000 (admin/admin123)"; fi
	@if docker-compose ps jaeger | grep -q "Up"; then echo "• Jaeger:         http://localhost:16686"; fi

health-check:
	@echo "Running health checks..."
	@curl -s http://localhost:8080/images > /dev/null && echo "✓ Engine API is healthy" || echo "✗ Engine API is not responding"
	@if docker-compose ps nginx | grep -q "Up"; then curl -s http://localhost/health > /dev/null && echo "✓ Nginx is healthy" || echo "✗ Nginx is not responding"; fi
	@if docker-compose ps prometheus | grep -q "Up"; then curl -s http://localhost:9090/-/healthy > /dev/null && echo "✓ Prometheus is healthy" || echo "✗ Prometheus is not responding"; fi
	@if docker-compose ps grafana | grep -q "Up"; then curl -s http://localhost:3000/api/health > /dev/null && echo "✓ Grafana is healthy" || echo "✗ Grafana is not responding"; fi
