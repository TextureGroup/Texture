# SPM Support

This directory contains the Swift Package Manager integration for Texture.

## Generating SPM Layout

Before building with SPM, you need to generate the symlink structure:

```bash
# From project root
swift scripts/generate_spm_sources_layout.swift
```

This will create `spm/Sources/AsyncDisplayKit/` with symlinks to the actual source files.

The symlinks are gitignored because they are generated files. In the future, this will be
replaced with a Swift Package Manager build tool plugin.

## Building with SPM

```bash
# Build with default traits (Video, MapKit, Photos, AssetsLibrary)
swift build

# Build with specific traits
swift build --traits IGListKit
swift build --traits Yoga
```

## Package Traits

- **Video** (default): Video node support with AVFoundation and CoreMedia
- **MapKit** (default): MapKit integration for map nodes
- **Photos** (default): Photos framework support
- **AssetsLibrary** (default): Legacy AssetsLibrary support (iOS only)
- **IGListKit** (optional): IGListKit integration for advanced collection view support
- **Yoga** (optional): Yoga layout engine support as an alternative layout system
