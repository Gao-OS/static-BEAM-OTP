# Static Erlang/OTP build
#
# Uses pkgsStatic.beamMinimalPackages which builds Erlang with musl
# and static linking, without wxwidgets (which requires libglvnd).

{ pkgs ? import <nixpkgs> {} }:

# beamMinimalPackages avoids wxwidgets/OpenGL dependencies
pkgs.pkgsStatic.beamMinimalPackages.erlang
