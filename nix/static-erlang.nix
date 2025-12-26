# Static Erlang/OTP build with musl libc
#
# Uses beamMinimal28Packages which is Erlang without wxwidgets.
# The base nixpkgs musl Erlang should produce binaries linked against musl.

{ pkgs ? import <nixpkgs> {} }:

let
  # Use musl-based cross compilation - nixpkgs handles the complexity
  pkgsMusl = pkgs.pkgsCross.musl64;

  # Use the minimal Erlang package without wxwidgets
  # Don't add extra static flags that cause cross-compilation issues
  erlangMusl = pkgsMusl.beamMinimal28Packages.erlang;

in erlangMusl
