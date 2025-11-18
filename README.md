## Quick start (Linux)
1. Build:
   go build -o mini-dockr ./cmd/dockr

2. Start engine API (run in a separate shell) — simple way:
   # Run API server
   go run ./internal/api/server.go

   (Alternatively, write a small main.go that calls api.NewServer and Run)

3. Build an image:
   tar -C examples/simple-app/rootfs -cf /tmp/app.tar .
   ./mini-dockr build /tmp/app.tar my-app

4. Run a container:
   ./mini-dockr run my-app /bin/sh -c "./app.sh"

5. List containers:
   ./mini-dockr ps

Notes:
- Must be run on Linux, many operations require root privileges (mount, chroot).
- This project is educational; for production you'd implement OCI specs, robust error handling and security.
