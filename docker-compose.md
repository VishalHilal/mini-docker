# Mini-Docker Docker Compose Setup

This directory contains Docker Compose configuration for running the mini-docker project.

## Services

### Engine
The main mini-docker engine API server that handles container operations.

- **Port**: 8080
- **Privileged**: Required for container operations
- **Volumes**: 
  - `mini-docker-registry:/tmp/mini-docker` (persistent storage)
  - `/var/run/docker.sock:/var/run/docker.sock` (Docker socket access)

### CLI (Testing)
A CLI client container for testing the engine API.

- **Profile**: `testing`
- **Depends on**: engine
- **Command**: Sleep infinity (for interactive use)

### Dev
Development environment with hot reload using Air.

- **Profile**: `dev`
- **Hot reload**: Enabled via Air
- **Volumes**: Source code mounted for live development

## Usage

### Quick Start with Helper Scripts
```bash
# Linux/Mac
./scripts/docker-helper.sh start

# Windows
.\scripts\docker-helper.bat start

# Start with testing profile
./scripts/docker-helper.sh start testing

# Start development environment
./scripts/docker-helper.sh start dev
```

### Manual Docker Compose Commands
```bash
# Start the engine only
docker-compose up engine

# Start engine and CLI for testing
docker-compose --profile testing up

# Start development environment
docker-compose --profile dev up
```

### Testing the CLI
```bash
# Connect to CLI container
docker-compose exec cli sh

# Test CLI commands
./mini-dockr build /examples/simple-app/rootfs my-app
./mini-dockr images
./mini-dockr run my-app /bin/sh -c "./app.sh"
./mini-dockr ps
./mini-dockr rm <container-id>
```

### Development
```bash
# Start development environment with hot reload
docker-compose --profile dev up

# View logs
docker-compose logs -f engine

# Stop services
docker-compose down
```

## Volumes

- `mini-docker-registry`: Persistent storage for images and container data

## Networks

- `mini-docker-net`: Bridge network for inter-service communication

## Requirements

- Docker
- Docker Compose
- Linux host (required for container operations)
- Root privileges (for mount, chroot operations)
