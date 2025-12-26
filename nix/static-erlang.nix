# Static Erlang/OTP build with musl libc
#
# Uses nixpkgs' existing musl cross-compilation support.
# Disables wxwidgets and other GUI components via configure flags.

{ pkgs ? import <nixpkgs> {} }:

let
  # Use musl-based cross compilation - nixpkgs handles the complexity
  pkgsMusl = pkgs.pkgsCross.musl64;

  # Override the Erlang package to disable wxwidgets and add static build flags
  erlangStatic = pkgsMusl.erlang.overrideAttrs (oldAttrs: {
    # Filter out wxGTK from buildInputs if present
    buildInputs = builtins.filter (p: !(pkgs.lib.hasPrefix "wxwidgets" (p.pname or "")))
      (oldAttrs.buildInputs or []);

    # Add configure flags to disable GUI components and enable static
    configureFlags = (oldAttrs.configureFlags or []) ++ [
      "--enable-static-nifs"
      "--enable-static-drivers"
      "--without-wx"
      "--without-observer"
      "--without-debugger"
      "--without-et"
      "--without-javac"
      "--without-odbc"
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
