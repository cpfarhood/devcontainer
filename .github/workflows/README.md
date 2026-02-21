# CI/CD Pipeline Guide

## 🚀 New Simplified Pipeline

### For Releases (Recommended)
Use the **Unified Release** workflow from GitHub Actions tab:
1. Go to Actions → Unified Release → Run workflow
2. Enter version number (e.g., 0.1.25) or choose release type
3. Click "Run workflow"

This single workflow:
- ✅ Updates chart version
- ✅ Creates git tag
- ✅ Builds and pushes Docker image with proper tags
- ✅ Publishes Helm chart
- ✅ Creates GitHub Release with notes
- ✅ **NO MORE `[skip ci]` NONSENSE!**

### For Quick Fixes
Use the **Quick Fix Build** workflow when you need to push a fix without ceremony:
1. Go to Actions → Quick Fix Build → Run workflow
2. Optionally specify a tag (defaults to 'latest')
3. Click "Run workflow"

This builds and pushes the Docker image immediately without version bumps.

## Workflow Files

| Workflow | Purpose | Trigger | What it does |
|----------|---------|---------|--------------|
| `release-unified.yaml` | **Main release workflow** | Manual dispatch | Complete release process |
| `quick-fix.yaml` | Emergency fixes | Manual dispatch | Just build & push Docker |
| `build-and-push.yaml` | CI builds | Tags & PRs | Auto-build on tags/PRs |
| `release.yaml` | GitHub releases | Tag push | Create GitHub release |
| `helm-publish.yaml` | Helm chart only | Tags | Publish Helm chart |

## Common Tasks

### Release a new version
```bash
# Option 1: Use GitHub UI
# Go to Actions → Unified Release → Run workflow

# Option 2: Use GitHub CLI
gh workflow run release-unified.yaml -f version=0.1.25 -f release_type=patch
```

### Push a quick fix
```bash
# Use GitHub UI: Actions → Quick Fix Build → Run workflow
# Or:
gh workflow run quick-fix.yaml -f tag=hotfix-1
```

### Check build status
```bash
gh run list --workflow=release-unified.yaml
```

## Version Strategy

- **Major** (1.0.0): Breaking changes
- **Minor** (0.2.0): New features
- **Patch** (0.1.25): Bug fixes

## Old Pipeline Issues (Now Fixed!)

❌ **REMOVED**: Auto-version-bump with `[skip ci]` that prevented Docker builds
❌ **REMOVED**: Disconnected workflows requiring manual tag juggling
❌ **REMOVED**: Complex multi-step process for releases

✅ **NEW**: Single unified workflow that does everything
✅ **NEW**: Manual control over versions
✅ **NEW**: Quick fix workflow for emergencies