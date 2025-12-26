# Static Erlang/OTP build
#
# Uses pkgsStatic which builds packages with static linking.
# This avoids cross-compilation complexity.

{ pkgs ? import <nixpkgs> {} }:

# pkgsStatic uses musl and static linking for all packages
pkgs.pkgsStatic.erlang
