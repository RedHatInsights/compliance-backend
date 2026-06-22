BASE_IMAGE ?= registry.access.redhat.com/ubi9/ubi-minimal@$(shell head -1 .baseimagedigest)

.PHONY: ubi.repo rpms.in.yaml generate-rpm-lockfile update-cargo-lockfile

# Extract the UBI repo configuration from the base image
ubi.repo:
	podman run --rm $(BASE_IMAGE) bash -c 'cat /etc/yum.repos.d/ubi.repo' > ubi.repo
	sed -i 's/ubi-9-codeready-builder/codeready-builder-for-ubi-9-$$basearch/' ubi.repo
	sed -i 's/\[ubi-9/[ubi-9-for-$$basearch/' ubi.repo

# Parse Dockerfile ARG declarations and generate rpms.in.yaml
rpms.in.yaml: Dockerfile .hermetic_builds/parse_dockerfile.rb
	ruby .hermetic_builds/parse_dockerfile.rb

# Resolve and lock all RPM dependencies.
# --image excludes packages already present in the base image from the lockfile.
generate-rpm-lockfile: ubi.repo rpms.in.yaml
	rpm-lockfile-prototype --image $(BASE_IMAGE) rpms.in.yaml --outfile rpms.lock.yaml

# Copy Cargo.toml and Cargo.lock from the prometheus-client-mmap gem into
# .hermetic_builds/cargo/ so Cachi2 can pre-fetch the required Rust crates.
# Run this after upgrading prometheus-client-mmap in Gemfile.lock.
update-cargo-lockfile:
	GEM=$$(bundle show prometheus-client-mmap)/ext/fast_mmaped_file_rs && \
	cp "$$GEM/Cargo.toml" .hermetic_builds/cargo/ && \
	cp "$$GEM/Cargo.lock" .hermetic_builds/cargo/
