package image

import (
	"archive/tar"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"
)

type Image struct {
	Name     string `json:"name"`
	ID       string `json:"id"`
	Rootfs   string `json:"rootfs"` 
	Created  int64  `json:"created"`
	Metadata map[string]string `json:"metadata"`
}

func BuildFromTar(tarPath, name, storageDir string) (*Image, error) {
	id := fmt.Sprintf("%d", time.Now().UnixNano())
	imgDir := filepath.Join(storageDir, "images", id)
	if err := os.MkdirAll(imgDir, 0755); err != nil { return nil, err }


	f, err := os.Open(tarPath)
	if err != nil { return nil, err }
	defer f.Close()
	tr := tar.NewReader(f)
	for {
		h, err := tr.Next()
		if err == io.EOF { break }
		if err != nil { return nil, err }
		target := filepath.Join(imgDir, h.Name)
		if h.Typeflag == tar.TypeDir {
			os.MkdirAll(target, 0755)
			continue
		}
		if h.Typeflag == tar.TypeReg {
			os.MkdirAll(filepath.Dir(target), 0755)
			out, err := os.Create(target)
			if err != nil { return nil, err }
			if _, err := io.Copy(out, tr); err != nil { out.Close(); return nil, err }
			out.Close()
			os.Chmod(target, os.FileMode(h.Mode))
		}
	}

	img := &Image{
		Name:    name,
		ID:      id,
		Rootfs:  imgDir,
		Created: time.Now().Unix(),
	}
	return img, nil
}
