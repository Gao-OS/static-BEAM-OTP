# Static Erlang/OTP build with musl libc
#
# STATUS: Work in Progress
#
# The nixpkgs musl/static Erlang builds currently fail due to missing
# bootstrap Erlang configuration in the cross-compilation setup.
#
# Known issues:
# - pkgsCross.musl64.erlang requires bootstrap erlang but doesn't configure it
# - pkgsStatic.erlang has the same bootstrap issue
# - All beamMinimal*Packages variants have the same problem
#
# This is a nixpkgs issue that needs to be fixed upstream.
# Tracking: https://github.com/NixOS/nixpkgs/issues
#
# Workaround options (not yet implemented):
# 1. Build Erlang in a native musl environment (Alpine container)
# 2. Use a Docker multi-stage build with Alpine
# 3. Wait for nixpkgs to fix the musl Erlang cross-compilation
#
# For development, use the regular Erlang from devenv (beam28Packages).

{ pkgs ? import <nixpkgs> {} }:

# TODO: This currently fails with "No usable Erlang/OTP system for the
# build machine found!" due to missing bootstrap erlang.
#
# Using beamMinimalPackages to avoid wxwidgets dependency issues.
pkgs.pkgsStatic.beamMinimalPackages.erlang
