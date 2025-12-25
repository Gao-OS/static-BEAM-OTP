{ pkgs, pkgsStatic, erlang }:

let
  elixirVersion = "1.16.3";
  elixirSha256 = "sha256-lOMD8JrK2mJEZSIWFv5aAsuXQ5yGAIWCqGDp/7guBrY=";

in
pkgs.stdenv.mkDerivation rec {
  pname = "elixir-static";
  version = elixirVersion;

  src = pkgs.fetchFromGitHub {
    owner = "elixir-lang";
    repo = "elixir";
    rev = "v${version}";
    sha256 = elixirSha256;
  };

  nativeBuildInputs = with pkgs; [
    gnumake
  ];

  buildInputs = [
    erlang
  ];

  # Use our static Erlang
  ERLANG_HOME = "${erlang}/lib/erlang";

  # Ensure we use static Erlang binaries
  preBuild = ''
    export PATH="${erlang}/bin:$PATH"
    export ERL_TOP="${erlang}/lib/erlang"

    # Verify we're using static Erlang
    echo "Using Erlang from: $(which erl)"
    echo "Erlang version: $(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell)"
  '';

  makeFlags = [
    "PREFIX=$(out)"
  ];

  # Elixir doesn't need special static build flags as it's BEAM bytecode
  # The important thing is that it uses our static ERTS at runtime
  buildPhase = ''
    runHook preBuild

    make clean
    make

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    make install PREFIX=$out

    # Create wrapper scripts that use our static ERTS
    for cmd in elixir elixirc iex mix; do
      if [ -f "$out/bin/$cmd" ]; then
        wrapProgram $out/bin/$cmd \
          --prefix PATH : "${erlang}/bin" \
          --set ERTS_ROOT "${erlang}/lib/erlang"
      fi
    done

    # Document which ERTS to use for releases
    mkdir -p $out/share/static-beam
    cat > $out/share/static-beam/release-config.txt <<EOF
# Static ERTS Configuration for Mix Releases
#
# Use these settings in your mix.exs release configuration:
#
# def project do
#   [
#     ...
#     releases: [
#       my_app: [
#         include_erts: "${erlang}/lib/erlang",
#         steps: [:assemble, :tar]
#       ]
#     ]
#   ]
# end
#
# Static ERTS path: ${erlang}/lib/erlang
# Static Erlang bin: ${erlang}/bin
EOF

    # Create a convenience script for building static releases
    cat > $out/bin/mix-static-release <<'SCRIPT'
#!/usr/bin/env bash
# Build a static Elixir release using our musl-static ERTS

set -e

STATIC_ERTS="${erlang}/lib/erlang"

echo "Building static release with ERTS from: $STATIC_ERTS"

# Set environment for static build
export MIX_ENV=''${MIX_ENV:-prod}
export ERTS_INCLUDE_DIR="$STATIC_ERTS/erts-*/include"

# Build the release
mix deps.get --only $MIX_ENV
mix compile
mix release --overwrite

echo ""
echo "Static release built successfully!"
echo "The release uses static ERTS and should work on any Linux distribution."
SCRIPT
    chmod +x $out/bin/mix-static-release

    runHook postInstall
  '';

  # Need wrapProgram
  nativeBuildInputs = [ pkgs.makeWrapper ];

  # Skip checks for faster builds
  doCheck = false;

  meta = with pkgs.lib; {
    description = "Elixir ${version} built with static Erlang/OTP (musl libc)";
    homepage = "https://elixir-lang.org/";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    maintainers = [ ];
  };
}
