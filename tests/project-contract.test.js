import assert from "node:assert/strict";
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../", import.meta.url));

function readJson(path) {
  return JSON.parse(readFileSync(join(root, path), "utf8"));
}

test("repository exposes the planned course entrypoints", () => {
  for (const path of [
    "install.ps1",
    "README.md",
    "LICENSE",
    "docs/getting-started.md",
    "docs/course-smoke-tests.md",
    "docs/example-prompts.md",
    "docs/troubleshooting.md",
    "examples/mcp/claude-code.mcp.json",
    "scripts/prepare-offline-cache.ps1",
    "scripts/install-unreal-mcp-bridge.ps1",
    ".github/workflows/ci.yml",
  ]) {
    assert.equal(existsSync(join(root, path)), true, `${path} should exist`);
  }
});

test("module manifests follow the installer contract", () => {
  const manifestDir = join(root, "manifests");
  const files = readdirSync(manifestDir).filter((file) => file.endsWith(".json"));

  assert.deepEqual(
    files.sort(),
    [
      "blender.json",
      "cc-switch.json",
      "claude-code.json",
      "game-studios.json",
      "godot.json",
      "toolchain.json",
      "unity.json",
      "unreal.json",
    ],
  );

  for (const file of files) {
    const manifest = readJson(`manifests/${file}`);
    assert.match(manifest.id, /^[a-z0-9-]+$/);
    assert.equal(typeof manifest.name, "string");
    assert.equal(typeof manifest.description, "string");
    assert.equal(typeof manifest.detect, "object");
    assert.equal(typeof manifest.install, "object");
    assert.equal(typeof manifest.configure, "object");
    assert.equal(typeof manifest.verify, "object");
    assert.ok(Array.isArray(manifest.cacheArtifacts));
    assert.equal(typeof manifest.rollbackNotes, "string");
  }
});

test("install script supports dry-run, offline cache, native Windows, WSL and redacted API capture", () => {
  const install = readFileSync(join(root, "install.ps1"), "utf8");

  for (const token of [
    "param(",
    "$OfflineCache",
    "$DryRun",
    "$IncludeWsl",
    "$WorkspacePath",
    "Read-Host -AsSecureString",
    "Write-HealthReport",
    "Test-OfflineArtifact",
    "Install-GameStudiosTemplate",
    "Configure-ClaudeMcp",
    "Configure-CcSwitch",
    "Invoke-ModuleLifecycle",
  ]) {
    assert.ok(install.includes(token), `install.ps1 should contain ${token}`);
  }

  assert.equal(/Write-(Host|Output).*(Api|Key|Secret|Token)/i.test(install), false);
});

test("CC Switch installation uses Windows releases instead of npm package guesswork", () => {
  const install = readFileSync(join(root, "install.ps1"), "utf8");
  const manifest = readJson("manifests/cc-switch.json");

  assert.ok(install.includes("Install-CcSwitchRelease"));
  assert.ok(install.includes("https://api.github.com/repos/farion1231/cc-switch/releases/latest"));
  assert.ok(install.includes("Windows.msi"));
  assert.equal(install.includes("npm install -g cc-switch"), false);
  assert.equal(manifest.install.strategy, "github-release-windows-installer");
});

test("Claude Code MCP example includes all four engine integrations", () => {
  const config = readJson("examples/mcp/claude-code.mcp.json");
  assert.deepEqual(Object.keys(config.mcpServers).sort(), ["blender", "godot", "unity", "unreal-engine"]);
  assert.equal(config.mcpServers["unreal-engine"].type, "http");
  assert.equal(config.mcpServers["unreal-engine"].url, "http://localhost:3000/mcp");
});

test("offline cache helper reads manifests and avoids secret material", () => {
  const helper = readFileSync(join(root, "scripts/prepare-offline-cache.ps1"), "utf8");

  for (const token of [
    "$CachePath",
    "manifests",
    "cacheArtifacts",
    "Get-FileHash",
    "Invoke-WebRequest",
    "manifest-cache-index.json",
  ]) {
    assert.ok(helper.includes(token), `prepare-offline-cache.ps1 should contain ${token}`);
  }

  assert.equal(/api[_-]?key|secret|token/i.test(helper), false);
});

test("CI validates PowerShell, manifests, docs and installer dry-run", () => {
  const ci = readFileSync(join(root, ".github/workflows/ci.yml"), "utf8");

  for (const token of [
    "windows-latest",
    "npm test",
    "PSScriptAnalyzer",
    "Parser]::ParseFile",
    "./install.ps1 -DryRun -IncludeWsl",
  ]) {
    assert.ok(ci.includes(token), `CI should contain ${token}`);
  }
});
