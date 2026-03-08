# Helium Flatpak

[![Build and Release](https://github.com/MarioGK/helium-flatpak/actions/workflows/build-release.yml/badge.svg)](https://github.com/MarioGK/helium-flatpak/actions/workflows/build-release.yml)

This repository contains the [Flatpak](https://flatpak.org/) manifest for **Helium**, a private, fast, and honest web browser based on Ungoogled Chromium.

It wraps the official prebuilt binaries from the [Helium Linux project](https://github.com/imputnet/helium-linux) into a sandboxed Flatpak environment, ensuring it runs securely and consistently across different Linux distributions.

---

## Installation

### Option 1: Install from Repository (Recommended)

Installing from the repository enables automatic updates via `flatpak update`.

**Add the repository:**
```bash
flatpak remote-add --user --if-not-exists helium https://mariogk.github.io/helium-flatpak/helium.flatpakrepo
```

**Install Helium:**
```bash
flatpak install --user helium net.imput.helium
```

**Or use the flatpakref file for one-click install:**
```bash
flatpak install --user https://mariogk.github.io/helium-flatpak/helium.flatpakref
```

### Option 2: Install from Bundle

Download the latest `.flatpak` bundle from the [**Releases Page**](https://github.com/MarioGK/helium-flatpak/releases) and install it:

```bash
flatpak install --user helium-[VERSION]-[ARCH].flatpak
```

*Note: On some distributions, you can simply double-click the downloaded file to install it via your Software Center.*

---

## Updating

If you installed from the repository, update Helium with:

```bash
flatpak update net.imput.helium
```

Or update all your Flatpaks at once:

```bash
flatpak update
```

If you installed from a bundle, you'll need to download and install a new bundle for each update.

---

## Building from Source

If you want to build the package yourself or contribute to the manifest, follow these steps.

### Prerequisites
Ensure you have `flatpak` and `flatpak-builder` installed. You also need the Flathub repository enabled to download the Freedesktop SDK/Runtime (version 24.08).

```bash
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install org.freedesktop.Sdk/x86_64/24.08
```

### Build & Install
Run the following command in the root of this repository. This will download the binary, build the sandbox, and install it to your user directory.

For x86_64 systems:

```bash
flatpak-builder --arch=x86_64 --user --install --force-clean build-dir net.imput.helium.yml
```

For ARM64 systems:

```bash
flatpak-builder --arch=aarch64 --user --install --force-clean build-dir net.imput.helium.yml
```

*Note: to install for all users, use sudo and replace '--user' with '--system'.*

---

## Running the App

Once installed (via repository, bundle, or local build), you can launch Helium from your application menu or via the terminal:

```bash
flatpak run net.imput.helium
```

---

## Uninstallation

To remove Helium and its data:

```bash
flatpak uninstall net.imput.helium
# Remove the repository (optional)
flatpak remote-delete helium
# Optional: Remove app data
rm -rf ~/.var/app/net.imput.helium
```

---

## Automated Updates

This repository automatically checks for new Helium releases and creates pull requests with updated manifests. When merged, the build workflow creates a new release and updates the repository.

---

## Flathub Submission

This manifest uses prebuilt binaries from the upstream Helium project. For Flathub submission, building from source would be required. This repository serves as a personal distribution method while maintaining Flathub-compatible structure.

---

**Disclaimer:** This is an unofficial packaging project. For issues related to the browser itself, please refer to the [upstream repository](https://github.com/imputnet/helium). For packaging issues, feel free to open an issue here.

---

## Acknowledgments

This project was initially based on [ShyVortex/helium-flatpak](https://github.com/ShyVortex/helium-flatpak).
