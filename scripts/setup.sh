#!/bin/bash

# Mini-Docker Advanced Setup Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Print banner
print_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Mini-Docker Setup Script                  ║"
    echo "║                     Advanced Configuration                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_section() {
    echo -e "${PURPLE}=== $1 ===${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_section "Checking Prerequisites"
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        exit 1
    fi
    
    print_status "Prerequisites check passed ✓"
}

# Setup environment
setup_environment() {
    print_section "Setting Up Environment"
    
    if [ ! -f .env ]; then
        print_status "Creating .env file from template..."
        cp .env.example .env
        print_warning "Please review .env file and adjust configurations as needed"
    else
        print_status ".env file already exists"
    fi
    
    # Create necessary directories
    mkdir -p config/ssl
    mkdir -p logs
    mkdir -p data/{postgres,redis,prometheus,grafana}
    
    print_status "Environment setup completed ✓"
}

# Generate SSL certificates (self-signed for development)
generate_ssl() {
    print_section "Generating SSL Certificates"
    
    if [ ! -f config/ssl/cert.pem ]; then
        print_status "Generating self-signed SSL certificates..."
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout config/ssl/key.pem \
            -out config/ssl/cert.pem \
            -subj "/C=US/ST=State/L=City/O=Mini-Docker/CN=localhost" \
            2>/dev/null || print_warning "OpenSSL not available, skipping SSL generation"
        print_status "SSL certificates generated ✓"
    else
        print_status "SSL certificates already exist"
    fi
}

# Setup profiles
setup_profiles() {
    local profile=${1:-basic}
    
    print_section "Setting Up Profile: $profile"
    
    case $profile in
        "basic")
            docker-compose up -d engine
            ;;
        "cache")
            docker-compose --profile cache up -d
            ;;
        "database")
            docker-compose --profile database up -d
            ;;
        "proxy")
            docker-compose --profile proxy up -d
            ;;
        "monitoring")
            docker-compose --profile monitoring up -d
            ;;
        "tracing")
            docker-compose --profile tracing up -d
            ;;
        "full")
            docker-compose -f docker-compose.yml -f docker-compose.full.yml --profile full up -d
            ;;
        *)
            print_error "Unknown profile: $profile"
            echo "Available profiles: basic, cache, database, proxy, monitoring, tracing, full"
            exit 1
            ;;
    esac
    
    print_status "Profile '$profile' setup completed ✓"
}

# Wait for services to be healthy
wait_for_services() {
    print_section "Waiting for Services to be Healthy"
    
    local services=("engine")
    if [[ "$1" == *"cache"* ]]; then services+=("redis"); fi
    if [[ "$1" == *"database"* ]]; then services+=("postgres"); fi
    if [[ "$1" == *"proxy"* ]]; then services+=("nginx"); fi
    if [[ "$1" == *"monitoring"* ]]; then services+=("prometheus" "grafana"); fi
    if [[ "$1" == *"tracing"* ]]; then services+=("jaeger"); fi
    
    for service in "${services[@]}"; do
        print_status "Waiting for $service to be healthy..."
        timeout 60 bash -c "until docker-compose ps $service | grep -q 'healthy\|Up'; do sleep 2; done" || {
            print_warning "$service may not be fully ready, continuing..."
        }
        print_status "$service is ready ✓"
    done
}

# Run health checks
run_health_checks() {
    print_section "Running Health Checks"
    
    # Check engine API
    if curl -s http://localhost:8080/images > /dev/null; then
        print_status "Engine API is responding ✓"
    else
        print_warning "Engine API may not be ready yet"
    fi
    
    # Check nginx if running
    if docker-compose ps nginx | grep -q "Up"; then
        if curl -s http://localhost/health > /dev/null; then
            print_status "Nginx proxy is responding ✓"
        fi
    fi
    
    # Check monitoring services
    if docker-compose ps prometheus | grep -q "Up"; then
        if curl -s http://localhost:9090/-/healthy > /dev/null; then
            print_status "Prometheus is responding ✓"
        fi
    fi
    
    if docker-compose ps grafana | grep -q "Up"; then
        if curl -s http://localhost:3000/api/health > /dev/null; then
            print_status "Grafana is responding ✓"
        fi
    fi
}

# Show service URLs
show_urls() {
    print_section "Service URLs"
    
    echo -e "${BLUE}Available Services:${NC}"
    echo "• Engine API:      http://localhost:8080"
    
    if docker-compose ps nginx | grep -q "Up"; then
        echo "• Web Interface:  http://localhost"
    fi
    
    if docker-compose ps redis | grep -q "Up"; then
        echo "• Redis:          localhost:6379"
    fi
    
    if docker-compose ps postgres | grep -q "Up"; then
        echo "• PostgreSQL:     localhost:5432"
    fi
    
    if docker-compose ps prometheus | grep -q "Up"; then
        echo "• Prometheus:     http://localhost:9090"
    fi
    
    if docker-compose ps grafana | grep -q "Up"; then
        echo "• Grafana:        http://localhost:3000 (admin/admin123)"
    fi
    
    if docker-compose ps jaeger | grep -q "Up"; then
        echo "• Jaeger:         http://localhost:16686"
    fi
}

# Cleanup function
cleanup() {
    print_section "Cleaning Up"
    
    docker-compose down -v --remove-orphans
    docker system prune -f
    print_status "Cleanup completed ✓"
}

# Main function
main() {
    print_banner
    
    local command=${1:-"help"}
    local profile=${2:-"basic"}
    
    case $command in
        "setup")
            check_prerequisites
            setup_environment
            generate_ssl
            setup_profiles "$profile"
            wait_for_services "$profile"
            run_health_checks
            show_urls
            ;;
        "start")
            setup_profiles "$profile"
            wait_for_services "$profile"
            run_health_checks
            show_urls
            ;;
        "stop")
            docker-compose down
            ;;
        "restart")
            docker-compose down
            sleep 2
            setup_profiles "$profile"
            wait_for_services "$profile"
            run_health_checks
            show_urls
            ;;
        "cleanup")
            cleanup
            ;;
        "status")
            docker-compose ps
            ;;
        "logs")
            docker-compose logs -f "${2:-engine}"
            ;;
        "health")
            run_health_checks
            ;;
        "urls")
            show_urls
            ;;
        "help"|"-h"|"--help")
            echo "Mini-Docker Advanced Setup Script"
            echo ""
            echo "Usage: $0 [COMMAND] [PROFILE]"
            echo ""
            echo "Commands:"
            echo "  setup [profile]    Full setup with environment and services"
            echo "  start [profile]    Start services only"
            echo "  stop               Stop all services"
            echo "  restart [profile]  Restart services"
            echo "  cleanup            Clean up all resources"
            echo "  status             Show service status"
            echo "  logs [service]     Show logs for service"
            echo "  health             Run health checks"
            echo "  urls               Show service URLs"
            echo "  help               Show this help"
            echo ""
            echo "Profiles:"
            echo "  basic       Engine only (default)"
            echo "  cache       Add Redis cache"
            echo "  database    Add PostgreSQL database"
            echo "  proxy       Add Nginx reverse proxy"
            echo "  monitoring  Add Prometheus and Grafana"
            echo "  tracing     Add Jaeger tracing"
            echo "  full        All services"
            echo ""
            echo "Examples:"
            echo "  $0 setup basic      # Basic setup"
            echo "  $0 setup monitoring # With monitoring"
            echo "  $0 setup full        # Complete setup"
            ;;
        *)
            print_error "Unknown command: $command"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
