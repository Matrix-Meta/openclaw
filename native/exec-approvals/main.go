package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
)

type AllowlistEntry struct {
	ID              string `json:"id,omitempty"`
	Pattern         string `json:"pattern"`
	LastUsedAt      int64  `json:"lastUsedAt,omitempty"`
	LastUsedCommand string `json:"lastUsedCommand,omitempty"`
	LastResolvedPath string `json:"lastResolvedPath,omitempty"`
}

type CommandResolution struct {
	RawExecutable   string `json:"rawExecutable"`
	ResolvedPath    string `json:"resolvedPath,omitempty"`
	ExecutableName string `json:"executableName"`
}

var (
	allowlist     []AllowlistEntry
	allowlistMutex sync.RWMutex
	compiledRegex = make(map[string]*regexp.Regexp)
	regexMutex    sync.RWMutex
)

func normalizePattern(pattern string) string {
	pattern = strings.TrimSpace(pattern)
	// Convert shell glob to regex
	pattern = regexp.QuoteMeta(pattern)
	pattern = strings.ReplaceAll(pattern, `\?`, ".")
	pattern = strings.ReplaceAll(pattern, `\*`, ".*")
	return pattern
}

func compilePattern(pattern string) *regexp.Regexp {
	regexMutex.RLock()
	if re, ok := compiledRegex[pattern]; ok {
		regexMutex.RUnlock()
		return re
	}
	regexMutex.RUnlock()

	normalized := normalizePattern(pattern)
	re, err := regexp.Compile("^" + normalized + "$")
	if err != nil {
		return nil
	}

	regexMutex.Lock()
	compiledRegex[pattern] = re
	regexMutex.Unlock()
	return re
}

func matchesPattern(command string, pattern string) bool {
	re := compilePattern(pattern)
	if re == nil {
		return false
	}
	return re.MatchString(command)
}

// Check if command matches any allowlist entry
func matchesAllowlist(command string, allowlist []AllowlistEntry) bool {
	for _, entry := range allowlist {
		if matchesPattern(command, entry.Pattern) {
			return true
		}
	}
	return false
}

// Resolve executable path
func resolveExecutablePath(rawExecutable string, cwd string, pathEnv string) CommandResolution {
	resolved := rawExecutable
	if strings.HasPrefix(resolved, "~/") {
		home := os.Getenv("HOME")
		if home != "" {
			resolved = filepath.Join(home, resolved[2:])
		}
	}

	if strings.Contains(resolved, "/") || strings.Contains(resolved, `\`) {
		if filepath.IsAbs(resolved) {
			if _, err := os.Stat(resolved); err == nil {
				return CommandResolution{
					RawExecutable:   rawExecutable,
					ResolvedPath:    resolved,
					ExecutableName: filepath.Base(resolved),
				}
			}
		}
		if cwd != "" {
			candidate := filepath.Join(cwd, resolved)
			if _, err := os.Stat(candidate); err == nil {
				return CommandResolution{
					RawExecutable:   rawExecutable,
					ResolvedPath:    candidate,
					ExecutableName:  filepath.Base(resolved),
				}
			}
		}
	}

	// Search in PATH
	entries := strings.Split(pathEnv, string(filepath.ListSeparator))
	ext := filepath.Ext(resolved)
	extensions := []string{""}
	if ext != "" {
		extensions = []string{""}
	} else if os.PathSeparator == '\\' {
		// Windows
		pathext := os.Getenv("PATHEXT")
		if pathext != "" {
			extensions = strings.Split(strings.ToLower(pathext), ";")
		}
	}

	for _, dir := range entries {
		if dir == "" {
			continue
		}
		for _, e := range extensions {
			candidate := filepath.Join(dir, resolved+e)
			if info, err := os.Stat(candidate); err == nil && !info.IsDir() {
				return CommandResolution{
					RawExecutable:   rawExecutable,
					ResolvedPath:    candidate,
					ExecutableName:  filepath.Base(resolved),
				}
			}
		}
	}

	return CommandResolution{
		RawExecutable:   rawExecutable,
		ExecutableName:  filepath.Base(resolved),
	}
}

// Parse first token from command
func parseFirstToken(command string) string {
	trimmed := strings.TrimSpace(command)
	if trimmed == "" {
		return ""
	}

	first := trimmed[0]
	if first == '"' || first == '\'' {
		end := strings.Index(trimmed[1:], string(first))
		if end > 0 {
			return trimmed[1 : end+1]
		}
		return trimmed[1:]
	}

	re := regexp.MustCompile(`^[^\s]+`)
	match := re.FindString(trimmed)
	return match
}

func main() {
	if len(os.Args) < 2 {
		return
	}

	switch os.Args[1] {
	case "matches":
		// Args: matches <command> <json-allowlist>
		if len(os.Args) < 4 {
			print("false")
			return
		}
		command := os.Args[2]
		var entries []AllowlistEntry
		if err := json.Unmarshal([]byte(os.Args[3]), &entries); err != nil {
			print("false")
			return
		}
		if matchesAllowlist(command, entries) {
			print("true")
		} else {
			print("false")
		}

	case "resolve":
		// Args: resolve <raw-executable> <cwd> <path-env>
		if len(os.Args) < 5 {
			return
		}
		raw := os.Args[2]
		cwd := os.Args[3]
		pathEnv := os.Args[4]
		if pathEnv == "" {
			pathEnv = os.Getenv("PATH")
		}

		res := resolveExecutablePath(raw, cwd, pathEnv)
		b, _ := json.Marshal(res)
		print(string(b))

	case "first-token":
		// Args: first-token <command>
		if len(os.Args) < 3 {
			return
		}
		print(parseFirstToken(os.Args[2]))
	}
}
