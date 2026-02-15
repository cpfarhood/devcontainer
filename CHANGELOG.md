# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project setup
- Antigravity IDE (VSCode) with web-based VNC access
- Happy Coder AI assistant integration
- Automatic GitHub repository cloning on startup
- Persistent home directory with ReadWriteMany PVC support
- Secure non-root execution (claude user, UID 1000, GID 1000)
- Support for private repositories via GitHub token
- HTTPRoute (Gateway API) support
- VNC password protection
- Multi-platform Docker image builds
- GitHub Actions CI/CD pipeline
- Automated releases on version tags
- Comprehensive deployment documentation (DEPLOYMENT.md)
- Complete variables reference (VARIABLES.md)

### Container Features
- Base: jlesage/baseimage-gui:ubuntu-22.04-v4
- Antigravity IDE (VSCode)
- Happy Coder npm package
- Chrome browser
- Node.js (LTS)
- Python 3
- Git

### Kubernetes Resources
- StatefulSet with volumeClaimTemplates
- ReadWriteMany PVC for /home directory
- ConfigMap for configuration
- Sealed Secrets support
- HTTPRoute for external access
- Service (headless)

### Configuration Options
- GitHub repository URL (required)
- GitHub token (optional, for private repos)
- VNC password (optional)
- Happy Coder server URL (optional)
- Happy Coder webapp URL (optional)
- Display resolution (configurable)
- Resource limits (configurable)
- Storage size (configurable)

### Documentation
- README.md with quick start guide
- DEPLOYMENT.md with step-by-step instructions
- VARIABLES.md with complete variable reference
- Release process documentation
- Pull request template
- Dependabot configuration

## Version History

No releases yet. See [Unreleased] section above for planned v1.0.0 features.

---

## Release Template

Use this template for future releases:

```markdown
## [1.0.0] - YYYY-MM-DD

### Added
- New features
- New configuration options

### Changed
- Changes to existing features
- Updated dependencies

### Deprecated
- Features that will be removed in future versions

### Removed
- Removed features
- Breaking changes

### Fixed
- Bug fixes
- Security patches

### Security
- Security improvements
- Vulnerability fixes
```

[Unreleased]: https://github.com/cpfarhood/devcontainer/compare/v1.0.0...HEAD
