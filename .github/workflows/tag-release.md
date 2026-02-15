# Release Process

This document describes how to create releases for this project.

## Semantic Versioning

We follow [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR** version (v2.0.0): Incompatible API/breaking changes
- **MINOR** version (v1.1.0): New features, backwards compatible
- **PATCH** version (v1.0.1): Bug fixes, backwards compatible

## Creating a Release

### Method 1: Using GitHub CLI (Recommended)

```bash
# Ensure you're on main branch and up to date
git checkout main
git pull

# Create and push a tag
VERSION="v1.0.0"  # Change this
git tag -a "$VERSION" -m "Release $VERSION

## What's New
- Feature 1
- Feature 2
- Bug fix 1

## Docker Image
\`\`\`bash
docker pull ghcr.io/cpfarhood/devcontainer:$VERSION
\`\`\`
"

git push origin "$VERSION"

# The GitHub Actions workflow will automatically:
# 1. Build the Docker image
# 2. Push to ghcr.io with multiple tags
# 3. Create a GitHub release with notes
```

### Method 2: Using Git Tags Only

```bash
git checkout main
git pull

# Create annotated tag
git tag -a v1.0.0 -m "Release v1.0.0"

# Push tag
git push origin v1.0.0
```

### Method 3: Using GitHub Web UI

1. Go to https://github.com/cpfarhood/devcontainer/releases
2. Click "Draft a new release"
3. Click "Choose a tag"
4. Type the new version (e.g., `v1.0.0`)
5. Click "Create new tag on publish"
6. Fill in the release title and description
7. Click "Publish release"

## What Happens Automatically

When you push a version tag (`v*`), GitHub Actions will:

1. **Build Docker image** with multiple tags:
   - `ghcr.io/cpfarhood/devcontainer:v1.2.3` (exact version)
   - `ghcr.io/cpfarhood/devcontainer:1.2` (minor version)
   - `ghcr.io/cpfarhood/devcontainer:1` (major version)
   - `ghcr.io/cpfarhood/devcontainer:latest` (if on default branch)

2. **Create GitHub Release** with:
   - Auto-generated release notes from commits
   - Docker pull command in the description

## Version Bump Guidelines

### Patch Release (v1.0.X)
- Bug fixes
- Documentation updates
- Minor dependency updates
- No new features
- No breaking changes

**Example:** v1.0.1
```bash
git tag -a v1.0.1 -m "Release v1.0.1 - Bug fixes"
git push origin v1.0.1
```

### Minor Release (v1.X.0)
- New features
- New optional configuration variables
- Enhancements to existing features
- Backwards compatible
- No breaking changes

**Example:** v1.1.0
```bash
git tag -a v1.1.0 -m "Release v1.1.0 - New Happy Coder features"
git push origin v1.1.0
```

### Major Release (vX.0.0)
- Breaking changes
- Required configuration changes
- Removal of deprecated features
- Incompatible API changes

**Example:** v2.0.0
```bash
git tag -a v2.0.0 -m "Release v2.0.0 - Breaking: New storage architecture"
git push origin v2.0.0
```

## Pre-releases

For alpha, beta, or release candidates:

```bash
# Alpha
git tag -a v1.1.0-alpha.1 -m "Release v1.1.0-alpha.1"
git push origin v1.1.0-alpha.1

# Beta
git tag -a v1.1.0-beta.1 -m "Release v1.1.0-beta.1"
git push origin v1.1.0-beta.1

# Release Candidate
git tag -a v1.1.0-rc.1 -m "Release v1.1.0-rc.1"
git push origin v1.1.0-rc.1
```

## Release Checklist

Before creating a release:

- [ ] All tests pass
- [ ] Documentation is up to date
- [ ] CHANGELOG.md is updated (if you maintain one)
- [ ] Version number follows semver
- [ ] On main/master branch
- [ ] All changes are committed
- [ ] Tag message includes release notes

## Docker Image Tags

Each release creates multiple Docker tags for flexibility:

| Git Tag | Docker Tags Created |
|---------|---------------------|
| v1.2.3 | `:v1.2.3`, `:1.2`, `:1`, `:latest` |
| v2.0.0 | `:v2.0.0`, `:2.0`, `:2`, `:latest` |
| v1.2.4-beta.1 | `:v1.2.4-beta.1`, `:1.2-beta` |

**Usage examples:**
```bash
# Specific version (recommended for production)
docker pull ghcr.io/cpfarhood/devcontainer:v1.2.3

# Minor version (gets patches automatically)
docker pull ghcr.io/cpfarhood/devcontainer:1.2

# Major version (gets minor updates and patches)
docker pull ghcr.io/cpfarhood/devcontainer:1

# Latest (always gets newest stable release)
docker pull ghcr.io/cpfarhood/devcontainer:latest
```

## Viewing Releases

- **GitHub Releases:** https://github.com/cpfarhood/devcontainer/releases
- **Docker Images:** https://github.com/cpfarhood/devcontainer/pkgs/container/devcontainer
- **Git Tags:** `git tag -l`

## Deleting a Release

If you need to delete a bad release:

```bash
# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin :refs/tags/v1.0.0

# Delete GitHub release (use web UI or gh CLI)
gh release delete v1.0.0
```

**Note:** Docker images pushed to ghcr.io cannot be easily deleted. It's better to create a new patch version.

## First Release

For the initial v1.0.0 release:

```bash
git checkout main
git pull

git tag -a v1.0.0 -m "Release v1.0.0 - Initial Release

## Features
- Antigravity IDE with web-based VNC access
- Happy Coder AI assistant integration
- Automatic GitHub repository cloning
- Persistent home directory with ReadWriteMany PVC
- Secure non-root execution (claude user, UID 1000)
- Support for private repositories with GitHub token
- HTTPRoute (Gateway API) support
- Multi-platform Docker images
- Comprehensive deployment documentation

## Docker Image
\`\`\`bash
docker pull ghcr.io/cpfarhood/devcontainer:v1.0.0
\`\`\`

## Deployment
See DEPLOYMENT.md for complete deployment instructions.
"

git push origin v1.0.0
```

## Example Release Workflow

```bash
# 1. Finish your feature/fix on a branch
git checkout feature/new-feature
git commit -m "feat: Add new feature"
git push

# 2. Create PR and merge to main
gh pr create
# ... get approval and merge ...

# 3. Pull latest main
git checkout main
git pull

# 4. Create release tag
git tag -a v1.1.0 -m "Release v1.1.0 - New feature"
git push origin v1.1.0

# 5. Wait for GitHub Actions
# - Check: https://github.com/cpfarhood/devcontainer/actions

# 6. Verify release
# - GitHub: https://github.com/cpfarhood/devcontainer/releases
# - Docker: docker pull ghcr.io/cpfarhood/devcontainer:v1.1.0
```
