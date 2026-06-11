# Hermetic Builds

The existing Konflux pipelines (`.tekton/compliance-backend-*.yaml`) run with
`hermetic: true`, meaning Cachi2 pre-fetches all dependencies before the build
starts and network access is blocked during the build itself.

## Prerequisites

- **`podman`** — used by `generate-repo-file`
- **`ruby`** — used by `generate-rpms-in-yaml`
- **`rpm-lockfile-prototype`** — Konflux's RPM dependency resolver:

  ```bash
  pip3 install --user git+https://github.com/konflux-ci/rpm-lockfile-prototype
  ```

  Source: https://github.com/konflux-ci/rpm-lockfile-prototype

## Dependency sets

Three dependency sets are locked and must be kept up to date:
- RPM packages (`rpms.lock.yaml` managed by `make generate-rpm-lockfile`
- Ruby gems (`Gemfile.lock` managed by bundler
- Rust crates (prometheus-client-mmap) (`.hermetic_builds/cargo/Cargo.lock`) copied from gem source

`prometheus-client-mmap` (a transitive dependency via `yabeda-prometheus-mmap`)
compiles a Rust extension (`fast_mmaped_file_rs`) during `bundle install`. When
Rust compiles, cargo tries to download crates from `crates.io` — which is
blocked in hermetic mode.

Cargo must be told to use those vendored crates instead of reaching
`crates.io`:

```toml
[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "/cachi2/output/deps/cargo"
```

## Regenerating the RPM lock file

Run whenever `Dockerfile` ARG packages or the base image change.
If the UBI repos publish a new version of a package that the lockfile depends on,
the lockfile becomes stale and the RPM install step will fail.

```bash
make generate-repo-file      # pull UBI repo list and normalise repo IDs for Clair
make generate-rpms-in-yaml   # parse Dockerfile ARGs into rpms.in.yaml
make generate-rpm-lockfile   # resolve full dependency graph
```

Do not edit `rpms.in.yaml` by hand. Commit `ubi.repo`, `rpms.in.yaml`, and
`rpms.lock.yaml` together after regenerating.

## Updating the Rust crate lockfile

If `prometheus-client-mmap` is upgraded in `Gemfile.lock`, copy the updated
Cargo files from the extracted gem source into `.hermetic_builds/cargo/`:

```bash
# Find the gem in your local bundle cache
GEM=$(find ~/.bundle ~/.local/share/gem -path "*/prometheus-client-mmap-*/ext/fast_mmaped_file_rs" 2>/dev/null | head -1)
cp "$GEM/Cargo.toml" .hermetic_builds/cargo/
cp "$GEM/Cargo.lock" .hermetic_builds/cargo/
```

## Notes

- **`HERMETIC` build arg** — `ARG HERMETIC="false"` defaults to off for local
  builds. The Tekton pipeline sets it to `"true"` via `build-args`. When true,
  two network-dependent steps are skipped in the Dockerfile: the PostgreSQL COPR
  repo setup and the `rpm -e tzdata` remove-and-reinstall pattern.

- **Bundler** — `gem install bundler` is not run; bundler 2.5.22 is provided by
  the `rubygem-bundler` RPM. Cachi2 sets `BUNDLE_MIRROR__ALL` to a local gem
  mirror so the auto-switch to the version in `BUNDLED WITH` resolves without
  network access.

- **PostgreSQL** — resolved from UBI repos (v13). The `pg` gem only needs
  `libpq-devel` headers to compile; the version difference from the COPR
  postgresql-16 used locally is not significant for the build.
