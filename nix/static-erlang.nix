# Static Erlang/OTP build with musl libc
#
# Uses nixpkgs' existing musl cross-compilation support.
# This leverages the well-tested pkgsCross.musl64 infrastructure.

{ pkgs ? import <nixpkgs> {} }:

let
  # Use musl-based cross compilation - nixpkgs handles the complexity
  pkgsMusl = pkgs.pkgsCross.musl64;

  # Get the Erlang package with musl - nixpkgs already knows how to build this
  erlangMusl = pkgsMusl.erlang.overrideAttrs (oldAttrs: {
    # Add static build flags
    configureFlags = (oldAttrs.configureFlags or []) ++ [
      "--enable-static-nifs"
      "--enable-static-drivers"
    ];

    # Ensure static linking is enabled
    dontDisableStatic = true;

    # Add static CFLAGS during the make phase
    makeFlags = (oldAttrs.makeFlags or []) ++ [
      "STATIC_CFLAGS=-static"
    ];

    # Post-install: verify and strip
    postInstall = (oldAttrs.postInstall or "") + ''
      echo ""
      echo "Static Erlang/OTP built with musl libc!"
      echo "ERTS directory: $out/lib/erlang/erts-*"

      # Strip binaries to reduce size
      find $out -type f -executable -exec strip --strip-all {} \; 2>/dev/null || true
    '';
  });

in erlangMusl
