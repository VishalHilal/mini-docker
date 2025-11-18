package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
)

const engineURL = "http://127.0.0.1:8080"

func main() {
	if len(os.Args) < 2 {
		usage()
		return
	}
	cmd := os.Args[1]
	switch cmd {
	case "build":
		if len(os.Args) < 4 {
			fmt.Println("usage: dockr build <path> <imagename>")
			return
		}
		path := os.Args[2]
		img := os.Args[3]
		build(path, img)
	case "images":
		images()
	case "run":
		if len(os.Args) < 4 {
			fmt.Println("usage: dockr run <imagename> <cmd...>")
			return
		}
		img := os.Args[2]
		cmds := os.Args[3:]
		run(img, cmds)
	case "ps":
		ps()
	case "rm":
		if len(os.Args) < 3 {
			fmt.Println("usage: dockr rm <container-id>")
			return
		}
		rm(os.Args[2])
	default:
		usage()
	}
}

func usage() {
	fmt.Println(`dockr - mini docker clone CLI
commands:
  build <path> <imagename>   Build an image from folder
  images                     List images
  run <imagename> <cmd...>   Run a container from image
  ps                         List running containers
  rm <container-id>          Remove (kill) container
`)
}

func build(path, imageName string) {
	tmp := filepath.Join(os.TempDir(), "mini-dockr-build.tar")
	err := tarDir(path, tmp)
	if err != nil {
		fmt.Println("tar error:", err)
		return
	}
	f, _ := os.Open(tmp)
	defer f.Close()

	req, _ := http.NewRequest("POST", engineURL+"/images/build?name="+imageName, f)
	req.Header.Set("Content-Type", "application/x-tar")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println("error:", err)
		return
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	fmt.Println(string(body))
}

func images() {
	resp, err := http.Get(engineURL + "/images")
	if err != nil { fmt.Println(err); return }
	defer resp.Body.Close()
	io.Copy(os.Stdout, resp.Body)
}

func run(image string, cmd []string) {
	b, _ := json.Marshal(map[string]interface{}{
		"image": image,
		"cmd":   cmd,
	})
	resp, err := http.Post(engineURL+"/containers/run", "application/json", bytes.NewReader(b))
	if err != nil { fmt.Println(err); return }
	defer resp.Body.Close()
	io.Copy(os.Stdout, resp.Body)
}

func ps() {
	resp, err := http.Get(engineURL + "/containers")
	if err != nil { fmt.Println(err); return }
	defer resp.Body.Close()
	io.Copy(os.Stdout, resp.Body)
}

func rm(id string) {
	req, _ := http.NewRequest("DELETE", engineURL+"/containers/"+id, nil)
	resp, err := http.DefaultClient.Do(req)
	if err != nil { fmt.Println(err); return }
	defer resp.Body.Close()
	io.Copy(os.Stdout, resp.Body)
}

func tarDir(src, dest string) error {
	cmd := execCommand("tar", "-C", src, "-cf", dest, ".")
	return cmd.Run()
}

func execCommand(name string, args ...string) *exec.Cmd {
	return exec.Command(name, args...)
}
