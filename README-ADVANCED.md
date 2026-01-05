# Mini-Docker Advanced Docker Compose Setup

This enhanced Docker Compose configuration provides a complete containerized environment for mini-docker with additional services for production-ready deployments.

## 🚀 Quick Start

```bash
# Complete setup with all services
make setup-full

# Or use the setup script directly
./scripts/setup.sh setup full

# Basic setup only
make setup-basic
```

## 📋 Available Services

### Core Services
- **Engine**: Mini-docker API server (port 8080)
- **CLI**: Command-line interface for testing

### Optional Services (via profiles)

#### 🗄️ Cache Profile
- **Redis**: In-memory caching and session storage
- Port: 6379
- Use: `make setup-cache`

#### 🐘 Database Profile  
- **PostgreSQL**: Metadata storage for images and containers
- Port: 5432
- Features: UUID support, JSONB metadata, automated schema
- Use: `make setup-database`

#### 🌐 Proxy Profile
- **Nginx**: Reverse proxy with load balancing and SSL termination
- Ports: 80 (HTTP), 443 (HTTPS)
- Features: Rate limiting, gzip compression, security headers
- Use: `make setup-proxy`

#### 📊 Monitoring Profile
- **Prometheus**: Metrics collection and storage
- Port: 9090
- **Grafana**: Visualization dashboard
- Port: 3000 (admin/admin123)
- Features: Pre-configured dashboards, data sources
- Use: `make setup-monitoring`

#### 🔍 Tracing Profile
- **Jaeger**: Distributed tracing for request tracking
- Port: 16686 (UI), 14268 (collector)
- Use: `make setup-tracing`

## 🎯 Usage Examples

### Basic Development
```bash
# Start engine only
make docker-start

# View logs
make docker-logs

# Test CLI
make docker-test
```

### Production Setup
```bash
# Full stack with monitoring
make setup-full

# Check service health
make health-check

# View all service URLs
make show-urls
```

### Development with Hot Reload
```bash
# Start development environment
make dev-start

# View development logs
make dev-logs
```

## 🔧 Configuration

### Environment Variables
Copy `.env.example` to `.env` and customize:

```bash
cp .env.example .env
# Edit .env with your preferences
```

Key configurations:
- `ENGINE_PORT`: API server port (default: 8080)
- `REDIS_PASSWORD`: Redis authentication
- `POSTGRES_PASSWORD`: PostgreSQL password
- `GRAFANA_PASSWORD`: Grafana admin password
- `NGINX_PORT`: Nginx HTTP port

### SSL Configuration
Self-signed certificates are auto-generated for development:
```bash
# Located in config/ssl/
# - cert.pem
# - key.pem
```

For production, replace with your own certificates.

## 📁 Project Structure

```
├── docker-compose.yml          # Basic services
├── docker-compose.full.yml     # Additional services
├── config/
│   ├── nginx.conf             # Nginx configuration
│   ├── prometheus.yml         # Prometheus config
│   ├── grafana/
│   │   ├── dashboards/        # Dashboard definitions
│   │   └── datasources/      # Data source configs
│   └── ssl/                  # SSL certificates
├── scripts/
│   ├── setup.sh              # Advanced setup script
│   ├── docker-helper.sh      # Unix helper script
│   ├── docker-helper.bat     # Windows helper script
│   └── init-db.sql           # PostgreSQL initialization
└── Makefile                  # Convenient commands
```

## 🏗️ Database Schema

The PostgreSQL setup includes:

### Tables
- **images**: Image metadata with layers and tags
- **containers**: Container runtime information
- **build_logs**: Build process logs
- **container_logs**: Container stdout/stderr logs

### Features
- UUID primary keys
- JSONB metadata storage
- Automated timestamps
- Performance indexes
- Pre-configured views

### Sample Queries
```sql
-- View container statistics
SELECT * FROM container_stats;

-- Get system overview
SELECT * FROM get_container_stats();
```

## 📈 Monitoring Setup

### Prometheus Metrics
- Engine API metrics
- Nginx performance metrics
- Redis operations
- PostgreSQL queries
- Container resource usage

### Grafana Dashboards
- System overview
- Container performance
- API response times
- Resource utilization

## 🛠️ Management Commands

### Setup Commands
```bash
make setup-basic       # Engine only
make setup-cache       # + Redis
make setup-database    # + PostgreSQL
make setup-proxy       # + Nginx
make setup-monitoring  # + Prometheus + Grafana
make setup-tracing     # + Jaeger
make setup-full        # All services
```

### Docker Commands
```bash
make docker-start      # Start services
make docker-stop       # Stop services
make docker-restart    # Restart services
make docker-status     # Show status
make docker-cleanup    # Clean resources
```

### Utility Commands
```bash
make show-urls         # Display service URLs
make health-check      # Verify service health
make build             # Build Go binaries
make test              # Run tests
make clean             # Clean artifacts
```

## 🔒 Security Features

- **Rate Limiting**: Nginx API rate limiting (10 req/s general, 2 req/s builds)
- **Security Headers**: XSS protection, content type options
- **Authentication**: Redis and PostgreSQL password protection
- **Network Isolation**: Custom Docker network (172.20.0.0/16)
- **SSL Support**: HTTPS configuration ready

## 🚨 Troubleshooting

### Common Issues
1. **Port conflicts**: Check `.env` file for port assignments
2. **Permission denied**: Ensure Docker daemon is running
3. **Service not ready**: Use `make health-check` to verify
4. **Resource limits**: Adjust Docker memory allocation

### Debug Commands
```bash
# View detailed logs
docker-compose logs -f [service-name]

# Check service health
curl http://localhost:8080/images

# Enter container shell
docker-compose exec engine sh

# Reset environment
make docker-cleanup
```

## 📚 Advanced Usage

### Custom Profiles
Create your own compose profiles by extending the base configuration:

```yaml
# docker-compose.custom.yml
version: '3.8'
services:
  custom-service:
    image: your-image
    profiles:
      - custom
```

### Environment-Specific Configs
```bash
# Development
cp .env.example .env.dev
docker-compose --env-file .env.dev up

# Production
cp .env.example .env.prod
# Edit .env.prod with production values
docker-compose --env-file .env.prod up
```

This enhanced setup provides a production-ready foundation for mini-docker with monitoring, persistence, and security features while maintaining simplicity for development use cases.
