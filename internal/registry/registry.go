package registry

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"mini-dockr/internal/image"
)

type LocalRegistry struct {
	base string
}

func NewLocalRegistry(base string) *LocalRegistry {
	os.MkdirAll(filepath.Join(base, "images"), 0755)
	return &LocalRegistry{base: base}
}

func (r *LocalRegistry) StoragePath() string { return r.base }

func (r *LocalRegistry) PushImage(img *image.Image) error {
	metaDir := filepath.Join(r.base, "images_meta")
	os.MkdirAll(metaDir, 0755)
	b, _ := json.Marshal(img)
	return os.WriteFile(filepath.Join(metaDir, img.ID+".json"), b, 0644)
}

func (r *LocalRegistry) ListImages() ([]*image.Image, error) {
	metaDir := filepath.Join(r.base, "images_meta")
	files, _ := os.ReadDir(metaDir)
	res := []*image.Image{}
	for _, f := range files {
		b, _ := os.ReadFile(filepath.Join(metaDir, f.Name()))
		var img image.Image
		json.Unmarshal(b, &img)
		res = append(res, &img)
	}
	return res, nil
}

func (r *LocalRegistry) GetImageByName(name string) (*image.Image, error) {
	images, _ := r.ListImages()
	for _, img := range images {
		if img.Name == name { return img, nil }
	}
	return nil, fmt.Errorf("image not found")
}
