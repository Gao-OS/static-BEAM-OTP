{ pkgs ? import <nixpkgs> {} }:

let
  # Static musl-based pkgs
  pkgsStatic = pkgs.pkgsCross.musl64.pkgsStatic;

  # Static dependencies
  openssl-static = pkgsStatic.openssl;
  ncurses-static = pkgsStatic.ncurses;
  zlib-static = pkgsStatic.zlib;

  # Erlang version - should match beam28Packages in devenv.nix
  erlangVersion = "28.2";
  erlangSha256 = "sha256-59IUTZrjDqmz3qVQOS3Ni35fD6TzosPnRSMsuR6vF4k=";

in
pkgsStatic.stdenv.mkDerivation rec {
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

  buildInputs = [
    openssl-static
    ncurses-static
    zlib-static
  ];

  # Force static linking
  NIX_CFLAGS_COMPILE = toString [
    "-static"
    "-I${openssl-static.dev}/include"
    "-I${ncurses-static.dev}/include"
    "-I${zlib-static.dev}/include"
  ];

  NIX_LDFLAGS = toString [
    "-static"
    "-L${openssl-static.out}/lib"
    "-L${ncurses-static.out}/lib"
    "-L${zlib-static.out}/lib"
  ];

  LDFLAGS = "-static -L${openssl-static.out}/lib -L${ncurses-static.out}/lib -L${zlib-static.out}/lib";
  CFLAGS = "-static -Os";

  # Cross-compilation configuration
  erl_xcomp_sysroot = pkgsStatic.stdenv.cc.libc;

  preConfigure = ''
    # Set up cross-compilation environment
    export erl_xcomp_sysroot="${pkgsStatic.stdenv.cc.libc}"

    # Debug: show what's in the OpenSSL directories
    echo "=== OpenSSL dev include ==="
    ls -la ${openssl-static.dev}/include/ || true
    echo "=== OpenSSL out lib ==="
    ls -la ${openssl-static.out}/lib/ || true
    echo "=== Looking for static libs ==="
    find ${openssl-static.out} -name "*.a" 2>/dev/null || echo "No .a files found in out"
    find ${openssl-static} -name "*.a" 2>/dev/null || echo "No .a files found in base"

    # Create merged OpenSSL directory by copying instead of symlinking
    export OPENSSL_MERGED=$NIX_BUILD_TOP/openssl-merged
    mkdir -p $OPENSSL_MERGED/lib
    cp -rL ${openssl-static.dev}/include $OPENSSL_MERGED/
    cp -L ${openssl-static.out}/lib/*.a $OPENSSL_MERGED/lib/ 2>/dev/null || true
    cp -rL ${openssl-static.out}/lib/pkgconfig $OPENSSL_MERGED/lib/ 2>/dev/null || true

    echo "=== Merged directory ==="
    ls -la $OPENSSL_MERGED/
    ls -la $OPENSSL_MERGED/lib/ || true

    ./otp_build autoconf

    substituteInPlace configure \
      --replace 'STATIC_CFLAGS=""' 'STATIC_CFLAGS="-static"'

    # Add SSL path to configure flags
    export configureFlags="$configureFlags --with-ssl=$OPENSSL_MERGED"
  '';

  configureFlags = [
    # Static build flags
    "--enable-static-nifs"
    "--enable-static-drivers"
    "--disable-dynamic-ssl-lib"
    "--disable-shared"

    # Disable unnecessary components
    "--without-javac"
    "--without-wx"
    "--without-odbc"
    "--without-megaco"
    "--without-observer"
    "--without-debugger"
    "--without-et"
    "--without-jinterface"

    # SSL is configured via preConfigure with merged directory

    # Terminal and compression
    "--with-termcap"
    "--enable-builtin-zlib"

    # Performance options
    "--enable-kernel-poll"
    "--enable-smp-support"
    "--enable-threads"
    "--enable-dirty-schedulers"

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
    if file erts/emulator/beam/beam.smp 2>/dev/null | grep -q "statically linked"; then
      echo "SUCCESS: beam.smp is statically linked"
    else
      echo "WARNING: beam.smp may not be fully static"
      file erts/emulator/beam/beam.smp || true
    fi
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
    description = "Erlang/OTP ${version} built statically with musl libc";
    homepage = "https://www.erlang.org/";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
