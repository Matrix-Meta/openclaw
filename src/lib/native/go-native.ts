/**
 * Go native module wrappers for shell-env and exec-approvals
 */
import { execFileSync } from "node:child_process";
import { cwd } from "node:process";
import path from "node:path";

function getNativeDir(): string {
  const distNative = path.resolve(cwd(), "dist/native");
  const fs = require("node:fs");
  if (fs.existsSync(distNative)) {
    return distNative;
  }
  return path.resolve(cwd(), "native");
}

/**
 * Get PATH from login shell using Go binary
 */
export function getShellPathFromLoginShell(
  shell: string = "/bin/sh",
  timeoutMs: number = 15000
): string | null {
  try {
    const nativeDir = getNativeDir();
    const bin = path.join(nativeDir, "shell-env/shell-env");
    const result = execFileSync(bin, ["get-shell-path", shell, String(timeoutMs)], {
      encoding: "utf8",
      timeout: timeoutMs + 1000,
    });
    return result.trim() || null;
  } catch {
    return null;
  }
}

/**
 * Check if command matches any allowlist pattern
 */
export function matchesAllowlist(
  command: string,
  allowlist: Array<{ pattern: string }>
): boolean {
  try {
    const nativeDir = getNativeDir();
    const bin = path.join(nativeDir, "exec-approvals/exec-approvals");
    const allowlistJson = JSON.stringify(allowlist.map(e => ({ pattern: e.pattern })));
    const result = execFileSync(bin, ["matches", command, allowlistJson], {
      encoding: "utf8",
      timeout: 5000,
    });
    return result.trim() === "true";
  } catch {
    return false;
  }
}

/**
 * Resolve executable path using Go binary
 */
export function resolveExecutablePathGo(
  rawExecutable: string,
  cwd: string = "",
  pathEnv: string = ""
): { rawExecutable: string; resolvedPath?: string; executableName: string } {
  try {
    const nativeDir = getNativeDir();
    const bin = path.join(nativeDir, "exec-approvals/exec-approvals");
    const result = execFileSync(bin, ["resolve", rawExecutable, cwd, pathEnv], {
      encoding: "utf8",
      timeout: 5000,
    });
    return JSON.parse(result.trim());
  } catch {
    return {
      rawExecutable,
      executableName: rawExecutable.split(/[\\/]/).pop() || rawExecutable,
    };
  }
}

/**
 * Parse first token from command
 */
export function parseFirstToken(command: string): string {
  try {
    const nativeDir = getNativeDir();
    const bin = path.join(nativeDir, "exec-approvals/exec-approvals");
    const result = execFileSync(bin, ["first-token", command], {
      encoding: "utf8",
      timeout: 5000,
    });
    return result.trim();
  } catch {
    // Fallback to simple parsing
    const trimmed = command.trim();
    if (!trimmed) return "";
    const first = trimmed[0];
    if (first === '"' || first === "'") {
      const end = trimmed.indexOf(first, 1);
      if (end > 1) return trimmed.slice(1, end);
      return trimmed.slice(1);
    }
    const match = /^[^\s]+/.exec(trimmed);
    return match ? match[0] : "";
  }
}
