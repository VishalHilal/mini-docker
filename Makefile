.PHONY: help build run test clean docker-start docker-stop docker-restart docker-logs docker-test docker-status docker-cleanup

# Default target
help:
	@echo "Mini-Docker Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  build          Build the Go binaries"
	@echo "  run-engine     Run the engine server"
	@echo "  run-cli        Run the CLI client"
	@echo "  test           Run tests"
	@echo "  clean          Clean build artifacts"
	@echo "  docker-start   Start Docker services"
	@echo "  docker-stop    Stop Docker services"
	@echo "  docker-restart Restart Docker services"
	@echo "  docker-logs    Show Docker logs"
	@echo "  docker-test    Test Docker setup"
	@echo "  docker-status  Show Docker status"
	@echo "  docker-cleanup Clean Docker resources"
	@echo ""
	@echo "Examples:"
	@echo "  make build"
	@echo "  make docker-start"
	@echo "  make docker-test"

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
