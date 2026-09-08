# Third-party notices

## sing-box / libbox

The Android build of TrueTun embeds a sing-box-derived mobile library (`libbox`) as its native runtime.

- Upstream project: SagerNet/sing-box
- Android runtime fork: Leadaxe/sing-box-lx
- Pinned Android binding version: `1.14.0-lx.35`
- Artifact: `libbox-1.14.0-lx.35.aar`
- Artifact SHA-256: `c4bc5f7b6aea3b022fff83421baeacbf672298cd167d828a6484cdbb1e896281`
- Upstream base: sing-box 1.14.x
- Extended feature used by TrueTun: XHTTP transport (`with_xhttp`)
- License: GNU General Public License version 3 or later (GPL-3.0-or-later)

The Android Gradle build downloads this exact AAR from the matching sing-box-lx GitHub Release and verifies the pinned SHA-256 before compilation. The version and digest must not be replaced with a floating or unverified artifact.

A release of the Android application must preserve the upstream and fork copyright/license notices and provide users with access to the Corresponding Source required by GPLv3.

TrueTun's repository-level Apache-2.0 license covers code for which the TrueTun contributors hold the relevant rights. It does not replace or weaken the license obligations of embedded third-party components. Distribution of an Android binary containing libbox must be reviewed and packaged for GPLv3 compliance.

Source locations:

- https://github.com/SagerNet/sing-box
- https://github.com/Leadaxe/sing-box-lx

For a reproducible release, record the exact libbox artifact version, digest, and sing-box-lx source revision used by the Android build in the release notes/build manifest.
