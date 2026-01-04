package main

import (
	"log"
	"os"

	api "github.com/VishalHilal/mini-docker/internal/server"
)

func main() {
	baseDir := "/tmp/mini-docker"
	if err := os.MkdirAll(baseDir, 0755); err != nil {
		log.Fatal("Failed to create base directory:", err)
	}

	s := api.NewServer(baseDir)
	log.Println("Starting mini-docker engine on :8080")
	if err := s.Run(":8080"); err != nil {
		log.Fatal("Server failed:", err)
	}
}
