# Core and licensing strategy

TrueTun should keep its own source independent from Hiddify application/core source.

## Why not directly embed `hiddify-core` now

At the time this architecture was created, the Hiddify core repository publishes GPLv3 text together with additional project-specific permissions/restrictions, including requirements around forks, attribution/share-alike and non-commercial use.

That makes it a poor default dependency for a new independent client unless TrueTun deliberately accepts those distribution constraints.

## Preferred approach

1. Implement TrueTun's own UI/domain/import/routing code.
2. Use a `ProxyCoreAdapter` boundary.
3. Target a sing-box-compatible core configuration.
4. Pin and audit the exact core distribution used for each release.
5. Keep an extended core optional and capability-gated.

The Hiddify sing-box fork is useful technically because it carries features such as XHTTP and Amnezia support, but it also has its own license obligations. Before shipping binaries, decide the final TrueTun license and verify compatibility with every linked/bundled component.

## Distribution checklist

Before the first public binary release:

- choose and add a TrueTun project license
- record core source/version/commit for every binary artifact
- include required core license notices/source offer as applicable
- verify whether Android native linking creates copyleft obligations for the app as a combined work
- verify Linux packaging model separately (bundled executable vs library)
- do not use Hiddify names/branding in a way that implies endorsement

This file is engineering guidance, not legal advice.
