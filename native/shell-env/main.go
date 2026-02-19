package main

import (
	"context"
	"os"
	"os/exec"
	"strings"
	"sync"
	"time"
)

var (
	cachedShellPath *string
	cachedPathMutex sync.RWMutex
)

func execLoginShellEnvZero(shell string, timeoutMs int) ([]byte, error) {
	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(timeoutMs)*time.Millisecond)
	defer cancel()

	cmd := exec.CommandContext(ctx, shell, "-l", "-c", "env -0")
	cmd.Env = os.Environ()
	return cmd.Output()
}

func parseShellEnv(stdout []byte) map[string]string {
	shellEnv := make(map[string]string)
	parts := strings.Split(string(stdout), "\x00")
	for _, part := range parts {
		if part == "" {
			continue
		}
		eq := strings.Index(part, "=")
		if eq <= 0 {
			continue
		}
		key := part[:eq]
		value := part[eq+1:]
		if key == "" {
			continue
		}
		shellEnv[key] = value
	}
	return shellEnv
}

func main() {
	// CLI mode: shell-env get-shell-path <shell> <timeoutMs>
	if len(os.Args) < 2 {
		return
	}

	switch os.Args[1] {
	case "get-shell-path":
		if len(os.Args) < 4 {
			return
		}
		shell := os.Args[2]
		timeoutMs := 15000
		if len(os.Args) > 3 {
			if t := strings.TrimSpace(os.Args[3]); t != "" {
				if parsed, err := time.ParseDuration(t + "ms"); err == nil {
					timeoutMs = int(parsed.Milliseconds())
				}
			}
		}

		output, err := execLoginShellEnvZero(shell, timeoutMs)
		if err != nil {
			os.Exit(1)
		}

		env := parseShellEnv(output)
		path, ok := env["PATH"]
		if !ok || path == "" {
			os.Exit(1)
		}
		print(path)

	case "get-env":
		if len(os.Args) < 4 {
			return
		}
		shell := os.Args[2]
		timeoutMs := 15000
		if len(os.Args) > 3 {
			if t := strings.TrimSpace(os.Args[3]); t != "" {
				if parsed, err := time.ParseDuration(t + "ms"); err == nil {
					timeoutMs = int(parsed.Milliseconds())
				}
			}
		}

		output, err := execLoginShellEnvZero(shell, timeoutMs)
		if err != nil {
			os.Exit(1)
		}

		env := parseShellEnv(output)
		// Output as JSON
		print(`{"`)
		first := true
		for k, v := range env {
			if !first {
				print(`","`)
			}
			print(k + `":"`)
			// Simple escape
			v = strings.ReplaceAll(v, `\`, `\\`)
			v = strings.ReplaceAll(v, `"`, `\"`)
			v = strings.ReplaceAll(v, "\n", `\n`)
			v = strings.ReplaceAll(v, "\r", `\r`)
			v = strings.ReplaceAll(v, "\t", `\t`)
			print(v + `"`)
			first = false
		}
		print(`}`)
	}
}
