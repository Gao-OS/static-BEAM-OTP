# Static Erlang/OTP build with musl libc
#
# Uses beamMinimal27Packages (OTP 27) which may have better
# cross-compilation support than OTP 28.

{ pkgs ? import <nixpkgs> {} }:

let
  # Use musl-based cross compilation
  pkgsMusl = pkgs.pkgsCross.musl64;

  # Use OTP 27 minimal (no wxwidgets) - may have better musl support
  erlangMusl = pkgsMusl.beamMinimal27Packages.erlang;

in erlangMusl
