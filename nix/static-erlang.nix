# Static Erlang/OTP build with musl libc
#
# NOTE: Building a fully static Erlang/OTP is complex due to:
# - Cross-compilation requirements for static musl builds
# - OpenSSL static library detection issues during configure
# - JIT/NIF compilation complications
#
# This derivation is a work in progress. For now, it builds Erlang with musl
# but without SSL/crypto support for simplicity.
#
# TODO: Resolve SSL static linking issues for full crypto support

{ pkgs ? import <nixpkgs> {} }:

let
  # Erlang version - should match beam28Packages in devenv.nix
  erlangVersion = "28.2";
  erlangSha256 = "sha256-59IUTZrjDqmz3qVQOS3Ni35fD6TzosPnRSMsuR6vF4k=";

  # Use musl-based cross compilation
  pkgsMusl = pkgs.pkgsCross.musl64;

in
pkgsMusl.stdenv.mkDerivation rec {
  pname = "erlang-static";
  version = erlangVersion;

  src = pkgs.fetchFromGitHub {
    owner = "erlang";
    repo = "otp";
    rev = "OTP-${version}";
    sha256 = erlangSha256;
  };

  nativeBuildInputs = with pkgs; [
    autoconf
    automake
    libtool
    perl
    gnumake
    m4
    # Bootstrap Erlang for cross-compilation
    erlang
  ];

  buildInputs = with pkgsMusl; [
    ncurses
    zlib
  ];

  # Force static linking
  LDFLAGS = "-static";
  CFLAGS = "-static -Os";

  postPatch = ''
    patchShebangs .
  '';

  preConfigure = ''
    export erl_xcomp_sysroot="${pkgsMusl.stdenv.cc.libc}"
    ./otp_build autoconf

    substituteInPlace configure \
      --replace 'STATIC_CFLAGS=""' 'STATIC_CFLAGS="-static"'
  '';

  configureFlags = [
    # Static build flags
    "--enable-static-nifs"
    "--enable-static-drivers"
    "--disable-shared"

    # Disable SSL for now (complex cross-compilation issues)
    "--without-ssl"

    # Disable GUI/external components
    "--without-javac"
    "--without-wx"
    "--without-odbc"
    "--without-megaco"
    "--without-observer"
    "--without-debugger"
    "--without-et"
    "--without-jinterface"

    # Terminal and compression
    "--with-termcap"
    "--enable-builtin-zlib"

    # Performance options
    "--enable-kernel-poll"
    "--enable-smp-support"
    "--enable-threads"
    "--enable-dirty-schedulers"

    # Disable JIT for static builds
    "--disable-jit"

    # Disable incompatible features
    "--disable-hipe"
    "--disable-lock-counter"
  ];

  makeFlags = [
    "LDFLAGS=-static"
    "STATIC_CFLAGS=-static"
  ];

  enableParallelBuilding = true;

  postBuild = ''
    echo "Checking if BEAM is statically linked..."
    file erts/emulator/beam/beam.smp || true
  '';

  postInstall = ''
    mkdir -p $out/bin

    # Remove unnecessary files
    rm -rf $out/lib/erlang/lib/*/examples
    rm -rf $out/lib/erlang/lib/*/doc
    rm -rf $out/lib/erlang/man

    # Strip binaries
    find $out -type f -executable -exec strip --strip-all {} \; 2>/dev/null || true

    echo ""
    echo "Static Erlang/OTP ${version} built successfully!"
    echo "ERTS directory: $out/lib/erlang/erts-*"
  '';

  doCheck = false;
  dontDisableStatic = true;

  meta = with pkgs.lib; {
    description = "Erlang/OTP ${version} built statically with musl libc (without SSL)";
    homepage = "https://www.erlang.org/";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
