#!/bin/bash

# Mini-Docker Helper Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Start services
start_services() {
    local profile=${1:-"basic"}
    
    print_status "Starting mini-docker services with profile: $profile"
    
    case $profile in
        "basic")
            docker-compose up -d engine
            ;;
        "testing")
            docker-compose --profile testing up -d
            ;;
        "dev")
            docker-compose --profile dev up -d
            ;;
        *)
            print_error "Unknown profile: $profile"
            echo "Available profiles: basic, testing, dev"
            exit 1
            ;;
    esac
    
    print_status "Services started successfully!"
}

# Stop services
stop_services() {
    print_status "Stopping mini-docker services..."
    docker-compose down
    print_status "Services stopped successfully!"
}

# Show logs
show_logs() {
    local service=${1:-"engine"}
    print_status "Showing logs for service: $service"
    docker-compose logs -f "$service"
}

# Test CLI commands
test_cli() {
    print_status "Testing CLI commands..."
    
    # Wait for engine to be healthy
    print_status "Waiting for engine to be healthy..."
    docker-compose wait engine
    
    # Execute test commands
    docker-compose exec cli go run ./cmd/docker/main.go images || true
    docker-compose exec cli go run ./cmd/docker/main.go ps || true
    
    print_status "CLI test completed!"
}

# Clean up resources
cleanup() {
    print_warning "Cleaning up mini-docker resources..."
    docker-compose down -v --remove-orphans
    docker system prune -f
    print_status "Cleanup completed!"
}

# Show status
show_status() {
    print_status "Mini-Docker Service Status:"
    docker-compose ps
}

# Main script logic
case "${1:-}" in
    "start")
        check_docker
        start_services "${2:-basic}"
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        stop_services
        sleep 2
        check_docker
        start_services "${2:-basic}"
        ;;
    "logs")
        show_logs "${2:-engine}"
        ;;
    "test")
        test_cli
        ;;
    "status")
        show_status
        ;;
    "cleanup")
        cleanup
        ;;
    "help"|"-h"|"--help")
        echo "Mini-Docker Helper Script"
        echo ""
        echo "Usage: $0 [COMMAND] [OPTIONS]"
        echo ""
        echo "Commands:"
        echo "  start [profile]    Start services (profiles: basic, testing, dev)"
        echo "  stop               Stop all services"
        echo "  restart [profile]  Restart services"
        echo "  logs [service]     Show logs for service (default: engine)"
        echo "  test               Test CLI commands"
        echo "  status             Show service status"
        echo "  cleanup            Clean up all resources"
        echo "  help               Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 start           # Start engine only"
        echo "  $0 start testing   # Start engine and CLI"
        echo "  $0 start dev       # Start development environment"
        echo "  $0 logs engine     # Show engine logs"
        echo "  $0 test            # Test CLI functionality"
        ;;
    *)
        print_error "Unknown command: ${1:-}"
        echo "Use '$0 help' for usage information."
        exit 1
        ;;
esac
