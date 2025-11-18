package runtime

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"syscall"
	"sync"
)

var (
	running = map[string]*os.Process{}
	mu sync.Mutex
)

type Runtime struct {
	storage string
	workdir string
}

func NewRuntime(storagePath string) *Runtime {
	base := filepath.Join(storagePath, "containers")
	os.MkdirAll(base, 0755)
	return &Runtime{storage: storagePath, workdir: base}
}

// RunContainer creates overlay mount and starts the container process
func (r *Runtime) RunContainer(imageName string, cmdArgs []string) (string, error) {
	// find image dir
	metaDir := filepath.Join(r.storage, "images_meta")
	// find image id by name
	var imageRoot string
	metas, _ := os.ReadDir(metaDir)
	for _, m := range metas {
		b, _ := os.ReadFile(filepath.Join(metaDir, m.Name()))
		if string(b) == "" { continue }
		// quick parse name
		type tmp struct { Name string `json:"name"`; Rootfs string `json:"rootfs"`; ID string `json:"id"` }
		var t tmp
		_ = json.Unmarshal(b, &t)
		if t.Name == imageName {
			imageRoot = t.Rootfs
			break
		}
	}
	if imageRoot == "" {
		return "", fmt.Errorf("image not found: %s", imageName)
	}
	id := fmt.Sprintf("%d", time.Now().UnixNano())
	containerRoot := filepath.Join(r.workdir, id)
	lower := imageRoot
	upper := filepath.Join(r.workdir, id, "upper")
	work := filepath.Join(r.workdir, id, "work")
	rootfs := filepath.Join(r.workdir, id, "rootfs")
	os.MkdirAll(upper, 0755)
	os.MkdirAll(work, 0755)
	os.MkdirAll(rootfs, 0755)

	// mount overlay: mount -t overlay overlay -o lowerdir=...,upperdir=...,workdir=... rootfs
	args := []string{"-t", "overlay", "overlay", "-o",
		fmt.Sprintf("lowerdir=%s,upperdir=%s,workdir=%s", lower, upper, work), rootfs}
	if out, err := exec.Command("mount", args...).CombinedOutput(); err != nil {
		return "", fmt.Errorf("mount overlay failed: %v: %s", err, string(out))
	}

	// prepare command: use /bin/sh inside rootfs if not provided
	execCmd := "/bin/sh"
	if len(cmdArgs) > 0 {
		execCmd = cmdArgs[0]
	}
	cmd := exec.Command(execCmd)
	cmd.SysProcAttr = &syscall.SysProcAttr{
		Cloneflags: syscall.CLONE_NEWUTS |
			syscall.CLONE_NEWPID |
			syscall.CLONE_NEWNS |
			syscall.CLONE_NEWNET,
		Chroot: rootfs,
	}
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Start(); err != nil {
		return "", err
	}

	mu.Lock()
	running[id] = cmd.Process
	mu.Unlock()

	go func() {
		cmd.Wait()
		// cleanup: umount
		exec.Command("umount", rootfs).Run()
		mu.Lock()
		delete(running, id)
		mu.Unlock()
	}()

	return id, nil
}

func ListRunningContainers() []map[string]interface{} {
	res := []map[string]interface{}{}
	mu.Lock()
	defer mu.Unlock()
	for id, p := range running {
		res = append(res, map[string]interface{}{"id": id, "pid": p.Pid})
	}
	return res
}

func KillContainer(id string) error {
	mu.Lock()
	defer mu.Unlock()
	if p, ok := running[id]; ok {
		if err := p.Kill(); err != nil {
			return err
		}
		delete(running, id)
		return nil
	}
	return fmt.Errorf("container not found")
}
