# CI/CD Pipeline Guide

## 🚀 Simplified Pipeline - Only 3 Workflows!

### 1️⃣ For Releases → **Unified Release**
Use this for all version releases:
1. Go to [Actions → Unified Release](https://github.com/cpfarhood/devcontainer/actions/workflows/release-unified.yaml)
2. Click "Run workflow"
3. Either:
   - Enter specific version (e.g., `0.2.1`), OR
   - Choose release type (patch/minor/major) for auto-increment
4. Click "Run workflow"

**This single workflow does EVERYTHING:**
- ✅ Updates chart version
- ✅ Creates git tag
- ✅ Builds Docker image with all proper tags
- ✅ Publishes Helm chart to GitHub Pages (`https://cpfarhood.github.io/devcontainer`)
- ✅ Creates GitHub Release with changelog
- ✅ No more `[skip ci]` blocking builds!

### 2️⃣ For Quick Fixes → **Quick Fix Build**
Use this for emergency fixes without version changes:
1. Go to [Actions → Quick Fix Build](https://github.com/cpfarhood/devcontainer/actions/workflows/quick-fix.yaml)
2. Click "Run workflow"
3. Enter tag (default: `latest`)
4. Click "Run workflow"

**Just builds and pushes Docker image** - no version bumps, no releases.

### 3️⃣ Automatic CI → **Build and Push**
Runs automatically on:
- Pull requests (builds but doesn't push)
- Tags starting with `v*` (builds and pushes)
- Manual trigger available

## Workflow Files

| Workflow | File | Purpose | When to Use |
|----------|------|---------|-------------|
| **Unified Release** | `release-unified.yaml` | Full release process | New versions |
| **Quick Fix Build** | `quick-fix.yaml` | Docker build only | Hotfixes |
| **Build and Push** | `build-and-push.yaml` | CI/CD automation | PRs & tags |

## Examples

### Release a new version
```bash
# Via GitHub UI (Recommended):
# Go to Actions → Unified Release → Run workflow

# Via GitHub CLI:
gh workflow run release-unified.yaml -f version=0.2.1
# OR auto-increment:
gh workflow run release-unified.yaml -f release_type=patch
```

### Push a quick fix
```bash
# Via GitHub UI:
# Go to Actions → Quick Fix Build → Run workflow

# Via GitHub CLI:
gh workflow run quick-fix.yaml -f tag=hotfix-1
```

### Check workflow status
```bash
# List all recent runs
gh run list --limit 5

# Watch a specific workflow
gh run watch
```

## Version Strategy

- **Major** (1.0.0): Breaking changes
- **Minor** (0.2.0): New features
- **Patch** (0.2.1): Bug fixes

## What We Fixed

### Before (Nightmare 😱)
- Auto-version-bump with `[skip ci]` prevented Docker builds
- 6+ disconnected workflows
- Manual tag deletion and re-pushing
- Version conflicts everywhere

### After (Simple! 🎉)
- **3 total workflows** (down from 6+)
- **1 button** for complete releases
- **No more `[skip ci]`** blocking builds
- **Clear separation** of concerns