# Third-party notices

## sing-box / libbox

TrueTun distributes sing-box-derived runtime components on Android and Linux.

### Runtime source

- Upstream project: SagerNet/sing-box
- Runtime fork: Leadaxe/sing-box-lx
- Pinned runtime version: `1.14.0-lx.35`
- sing-box-lx source revision for the tagged release: `5ea79ce2ba369153aeecc5fea273e0c05d30469d`
- Upstream base: sing-box 1.14.x
- Extended feature used by TrueTun: XHTTP transport
- License: GNU General Public License version 3 or later (GPL-3.0-or-later)

### Android artifact

- Artifact: `libbox-1.14.0-lx.35.aar`
- SHA-256: `c4bc5f7b6aea3b022fff83421baeacbf672298cd167d828a6484cdbb1e896281`

The Android Gradle build downloads this exact AAR from the matching sing-box-lx GitHub Release and verifies the pinned SHA-256 before compilation.

### Linux artifacts

- x86_64 artifact: `sing-box-1.14.0-lx.35-linux-amd64.tar.gz`
- x86_64 SHA-256: `36445e7f6818c652dda529b6ba7e02c3b5ae703328ee294c585c914f45734863`
- aarch64 artifact: `sing-box-1.14.0-lx.35-linux-arm64.tar.gz`
- aarch64 SHA-256: `3937ce411b78b14be2cc328ad37287f6a1ef61c50643c628af3209dfa4dfae74`

Linux release packaging downloads the architecture-specific archive, verifies its pinned digest and places the `sing-box` executable beside the TrueTun launcher. On first launch the launcher installs the same verified executable and a narrowly-scoped helper under `/usr/local/libexec/truetun` so the Flutter GUI itself remains unprivileged.

### License obligations

A release containing these runtime components must preserve the upstream and fork copyright/license notices and provide users with access to the Corresponding Source required by GPLv3.

TrueTun's repository-level Apache-2.0 license covers code for which the TrueTun contributors hold the relevant rights. It does not replace or weaken the license obligations of embedded third-party components.

Source locations:

- https://github.com/SagerNet/sing-box
- https://github.com/Leadaxe/sing-box-lx
- https://github.com/Leadaxe/sing-box-lx/tree/v1.14.0-lx.35

For reproducible releases, keep the exact runtime version, source revision, artifact names and SHA-256 digests in release notes or a build manifest.
