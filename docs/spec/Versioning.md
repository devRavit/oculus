# Versioning

## Semantic Versioning

Oculus uses [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH
```

- **MAJOR**: Breaking changes (API changes, DB schema changes requiring migration)
- **MINOR**: New features (new modules, new functionality)
- **PATCH**: Bug fixes, minor improvements

## Version Source

- **Single source of truth**: `Oculus/Oculus.toc` (`## Version:`)
- Core.lua reads version via `C_AddOns.GetAddOnMetadata()`
- No need to update version in multiple places

## Release Process

1. Update version in `Oculus/Oculus.toc`
2. Update `CHANGELOG.md` with changes
3. Create git tag: `git tag v0.1.0`
4. Push tag: `git push origin v0.1.0`

## Current Version

| Component | Version |
|-----------|---------|
| Core | 0.1.0 |
| RaidFrames | - (not released) |
| UnitFrames | - (not released) |
| ArenaFrames | - (not released) |

## Version History

See [CHANGELOG.md](/CHANGELOG.md) for detailed release notes.
