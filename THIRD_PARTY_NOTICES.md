# Third-party notices

## sing-box / libbox

The Android build of TrueTun embeds the sing-box mobile library (`libbox`) as a native runtime.

- Upstream project: SagerNet/sing-box
- Android packaging used by this project: singbox-android/libbox
- Pinned Android binding version: `1.14.0`
- Upstream sing-box release: `v1.14.0`
- License: GNU General Public License version 3 or later (GPL-3.0-or-later)

The Android Gradle dependency is intentionally pinned and must not be changed to a floating version. A release of the Android application must preserve the upstream copyright and license notices and provide users with access to the Corresponding Source required by GPLv3.

TrueTun's repository-level Apache-2.0 license covers code for which the TrueTun contributors hold the relevant rights. It does not replace or weaken the license obligations of embedded third-party components. Distribution of an Android binary containing libbox must be reviewed and packaged for GPLv3 compliance.

Upstream source locations:

- https://github.com/SagerNet/sing-box
- https://github.com/singbox-android/libbox

For a reproducible release, record the exact libbox artifact version and sing-box source revision used by the Android build in the release notes/build manifest.
