# RebuiltTux Ubuntu Based

A custom Ubuntu-based Linux distribution project.

## What this repository contains

RebuiltTux is being built as a real installable Linux OS rather than just a collection of configuration files. The repository will contain the filesystem layout, boot files, package configuration, system configuration, and build scripts needed to produce an ISO.

### Planned system tree

```text
filesystem/
├── etc/
│   ├── os-release
│   ├── hostname
│   ├── apt/
│   └── systemd/
├── usr/
│   ├── bin/
│   ├── lib/
│   └── share/
├── var/
├── home/
├── root/
├── boot/
└── opt/
```

Ubuntu's packages and core Linux components should be obtained through the normal Ubuntu package/build process rather than copied wholesale from an installed Ubuntu system. This keeps the resulting image reproducible and avoids accidentally including machine-specific files.

## Build direction

The eventual build system will assemble an Ubuntu base filesystem, install the selected packages, add RebuiltTux configuration and branding, create the bootable filesystem, and generate an ISO that can be tested in a VM.

## Status

🚧 Early development — the repository is currently being turned into the actual OS source/build tree.
