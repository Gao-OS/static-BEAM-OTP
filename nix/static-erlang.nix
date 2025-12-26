# Static Erlang/OTP build with musl libc
#
# Uses beamMinimal28Packages which is Erlang without wxwidgets.
# This avoids complex GUI dependencies that fail on musl.

{ pkgs ? import <nixpkgs> {} }:

let
  # Use musl-based cross compilation - nixpkgs handles the complexity
  pkgsMusl = pkgs.pkgsCross.musl64;

  # Use the minimal Erlang package without wxwidgets
  erlangMinimal = pkgsMusl.beamMinimal28Packages.erlang;

  # Apply static build configuration
  erlangStatic = erlangMinimal.overrideAttrs (oldAttrs: {
    # Add bootstrap Erlang for cross-compilation
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [
      pkgs.erlang  # Bootstrap Erlang from host
    ];

    # Patch shebangs in all scripts (especially utils/find_cross_ycf)
    postPatch = (oldAttrs.postPatch or "") + ''
      patchShebangs .
    '';

    # Add configure flags to enable static NIFs/drivers
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

    # Post-install: strip binaries
    postInstall = (oldAttrs.postInstall or "") + ''
      echo ""
      echo "Static Erlang/OTP built with musl libc!"
      echo "ERTS directory: $out/lib/erlang/erts-*"

      # Strip binaries to reduce size
      find $out -type f -executable -exec strip --strip-all {} \; 2>/dev/null || true
    '';
  });

in erlangStatic
