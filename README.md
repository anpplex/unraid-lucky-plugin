# Lucky x86_64 Unraid Plugin

This is a traditional Unraid `.plg` plugin for installing and running the Lucky Linux x86_64 binary directly. It does not use Docker.

Upstream Lucky:

- Project: https://github.com/gdy666/lucky
- Version: `2.27.2`
- Binary archive: `lucky_2.27.2_Linux_x86_64.tar.gz`
- Runtime command: `lucky -cd <config-dir>`
- Default Web UI: `http://<unraid-ip>:16601`
- Default login: `666 / 666`

## Installed Layout

- Binary: `/usr/local/lucky/lucky`
- Symlink: `/usr/local/sbin/lucky`
- Config directory: `/boot/config/plugins/lucky/luckyconf`
- Plugin config: `/boot/config/plugins/lucky/lucky.cfg`
- rc script: `/etc/rc.d/rc.lucky`
- Web UI page: `Settings / Lucky`
- Log: `/var/log/lucky.log`
- PID: `/var/run/lucky.pid`

## Build

```sh
./scripts/build-plugin.sh https://raw.githubusercontent.com/<owner>/<repo>/main
```

The build creates:

- `dist/lucky-x86_64.plg`: standalone installer with the x86_64 package embedded.
- `dist/lucky.plg`: repository installer that downloads `dist/packages/lucky-<version>-x86_64-1.txz`.
- `dist/packages/lucky-<version>-x86_64-1.txz`: Slackware-style Unraid package containing the Lucky binary and plugin files.

For a direct local install on Unraid, use:

```sh
installplg /path/to/lucky-x86_64.plg
```

For GitHub-hosted install, use the raw URL to `dist/lucky.plg`.

Current install URL:

```text
https://raw.githubusercontent.com/anpplex/unraid-lucky-plugin/main/dist/lucky.plg
```

## Tracking Lucky Releases

Run this locally to update the plugin to the latest Lucky x86_64 release:

```sh
./scripts/update-upstream.sh
./scripts/build-plugin.sh https://raw.githubusercontent.com/<owner>/<repo>/main
```

The updater reads the latest `gdy666/lucky` GitHub release, downloads `lucky_<version>_Linux_x86_64.tar.gz`, calculates its SHA256, then updates:

- `VERSION`
- `UPSTREAM_SHA256`
- `dist/upstream/lucky_<version>_Linux_x86_64.tar.gz`

The included GitHub Actions workflow runs daily and on demand. It rebuilds `dist/lucky.plg`, `dist/lucky-x86_64.plg`, and the matching `dist/packages/*.txz`, then commits the changed files.

Install users should use the raw URL to `dist/lucky.plg` for normal Unraid plugin updates. `dist/lucky-x86_64.plg` remains a standalone/offline installer.
