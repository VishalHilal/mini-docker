package api

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/gorilla/mux"

	"github.com/VishalHilal/mini-docker/internal/image"
	"github.com/VishalHilal/mini-docker/internal/registry"
	"github.com/VishalHilal/mini-docker/internal/runtime"
)

type Server struct {
	reg *registry.LocalRegistry
}

func NewServer(baseDir string) *Server {
	reg := registry.NewLocalRegistry(filepath.Join(baseDir, "registry"))
	return &Server{reg: reg}
}

func (s *Server) Run(addr string) error {
	r := mux.NewRouter()
	r.HandleFunc("/images/build", s.handleBuild).Methods("POST")
	r.HandleFunc("/images", s.handleImages).Methods("GET")
	r.HandleFunc("/containers/run", s.handleRun).Methods("POST")
	r.HandleFunc("/containers", s.handleListContainers).Methods("GET")
	r.HandleFunc("/containers/{id}", s.handleDeleteContainer).Methods("DELETE")
	return http.ListenAndServe(addr, r)
}

func (s *Server) handleBuild(w http.ResponseWriter, r *http.Request) {
	name := r.URL.Query().Get("name")
	if name == "" {
		http.Error(w, "missing name", http.StatusBadRequest)
		return
	}

	// Save incoming tar to temp file
	tmp := filepath.Join(os.TempDir(), fmt.Sprintf("build-%d.tar", time.Now().UnixNano()))
	f, err := os.Create(tmp)
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	defer f.Close()
	_, err = io.Copy(f, r.Body)
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}

	// build image (extract to layer dir)
	img, err := image.BuildFromTar(tmp, name, s.reg.StoragePath())
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}

	// register
	err = s.reg.PushImage(img)
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	w.Write([]byte("ok\n"))
}

func (s *Server) handleImages(w http.ResponseWriter, r *http.Request) {
	imgs, _ := s.reg.ListImages()
	json.NewEncoder(w).Encode(imgs)
}

func (s *Server) handleRun(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Image string   `json:"image"`
		Cmd   []string `json:"cmd"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), 400)
		return
	}

	// create runtime config
	rt := runtime.NewRuntime(s.reg.StoragePath())
	id, err := rt.RunContainer(req.Image, req.Cmd)
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	w.Write([]byte(id))
}

func (s *Server) handleListContainers(w http.ResponseWriter, r *http.Request) {
	containers := runtime.ListRunningContainers()
	json.NewEncoder(w).Encode(containers)
}

func (s *Server) handleDeleteContainer(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]
	err := runtime.KillContainer(id)
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	w.Write([]byte("ok"))
}
