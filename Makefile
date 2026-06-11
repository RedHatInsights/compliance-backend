BASE_IMAGE ?= registry.access.redhat.com/ubi9/ubi-minimal:latest

.PHONY: generate-repo-file generate-rpms-in-yaml generate-rpm-lockfile

# Extract the UBI repo configuration from the base image
generate-repo-file:
	podman run --rm $(BASE_IMAGE) bash -c 'cat /etc/yum.repos.d/ubi.repo' > ubi.repo
	sed -i 's/ubi-9-codeready-builder/codeready-builder-for-ubi-9-$$basearch/' ubi.repo
	sed -i 's/\[ubi-9/[ubi-9-for-$$basearch/' ubi.repo

# Parse Dockerfile ARG declarations and generate rpms.in.yaml
generate-rpms-in-yaml:
	ruby .hermetic_builds/parse_dockerfile.rb

# Resolve and lock all RPM dependencies (requires ubi.repo).
# --image excludes packages already present in the base image from the lockfile.
generate-rpm-lockfile:
	rpm-lockfile-prototype --image $(BASE_IMAGE) rpms.in.yaml --outfile rpms.lock.yaml
