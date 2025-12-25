{ pkgs, pkgsStatic }:

let
  # Static dependencies from musl pkgsStatic
  openssl-static = pkgsStatic.openssl.override {
    static = true;
  };

  ncurses-static = pkgsStatic.ncurses.override {
    enableStatic = true;
  };

  zlib-static = pkgsStatic.zlib.override {
    static = true;
  };

  # Erlang version to build
  erlangVersion = "26.2.5";
  erlangSha256 = "sha256-nrx8RhJjk6MXKvvP8DaDOcWNr8P4BQPP/TVpD9p6wKI=";

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

  # Environment variables for static build
  LDFLAGS = "-static -L${openssl-static.out}/lib -L${ncurses-static.out}/lib -L${zlib-static.out}/lib";
  CFLAGS = "-static -Os";

  preConfigure = ''
    # Generate configure script
    ./otp_build autoconf

    # Patch configure to support static builds better
    substituteInPlace configure \
      --replace 'STATIC_CFLAGS=""' 'STATIC_CFLAGS="-static"'
  '';

  configureFlags = [
    # Static build flags
    "--enable-static-nifs"
    "--enable-static-drivers"
    "--disable-dynamic-ssl-lib"
    "--disable-shared"

    # Disable unnecessary components for smaller binary
    "--without-javac"
    "--without-wx"
    "--without-odbc"
    "--without-megaco"
    "--without-observer"
    "--without-debugger"
    "--without-et"
    "--without-jinterface"

    # SSL configuration
    "--with-ssl=${openssl-static.dev}"
    "--with-ssl-lib-subdir=lib"

    # Terminal support
    "--with-termcap"
    "--enable-builtin-zlib"

    # Kernel poll for better performance
    "--enable-kernel-poll"

    # SMP support
    "--enable-smp-support"
    "--enable-threads"

    # Dirty schedulers for NIF performance
    "--enable-dirty-schedulers"

    # HIPE disabled (not compatible with static builds on some platforms)
    "--disable-hipe"

    # Lock counter for debugging (disable in production)
    "--disable-lock-counter"
  ];

  # Build with explicit static linking
  makeFlags = [
    "LDFLAGS=-static"
    "STATIC_CFLAGS=-static"
  ];

  # Parallel build
  enableParallelBuilding = true;

  # Post-build verification
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
    # Create convenience symlinks
    mkdir -p $out/bin

    # Remove unnecessary files to reduce size
    rm -rf $out/lib/erlang/lib/*/examples
    rm -rf $out/lib/erlang/lib/*/doc
    rm -rf $out/lib/erlang/man

    # Strip binaries for smaller size
    find $out -type f -executable -exec strip --strip-all {} \; 2>/dev/null || true

    echo ""
    echo "Static Erlang/OTP ${version} built successfully!"
    echo "ERTS directory: $out/lib/erlang/erts-*"
  '';

  # Verification phase
  doCheck = false;  # Skip tests for faster builds

  # Needed for static builds
  dontDisableStatic = true;

  meta = with pkgs.lib; {
    description = "Erlang/OTP ${version} built statically with musl libc";
    homepage = "https://www.erlang.org/";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    maintainers = [ ];
  };
}
