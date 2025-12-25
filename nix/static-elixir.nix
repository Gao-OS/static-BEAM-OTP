{ pkgs ? import <nixpkgs> {} }:

let
  # Import the static Erlang we built
  staticErlang = import ./static-erlang.nix { inherit pkgs; };

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
    makeWrapper
  ];

  buildInputs = [
    staticErlang
  ];

  ERLANG_HOME = "${staticErlang}/lib/erlang";

  preBuild = ''
    export PATH="${staticErlang}/bin:$PATH"
    export ERL_TOP="${staticErlang}/lib/erlang"

    echo "Using Erlang from: $(which erl)"
  '';

  makeFlags = [
    "PREFIX=$(out)"
  ];

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
          --prefix PATH : "${staticErlang}/bin" \
          --set ERTS_ROOT "${staticErlang}/lib/erlang"
      fi
    done

    # Document static ERTS path
    mkdir -p $out/share/static-beam
    cat > $out/share/static-beam/release-config.txt <<EOF
# Static ERTS Configuration for Mix Releases
#
# Use in mix.exs:
#   releases: [
#     my_app: [
#       include_erts: "${staticErlang}/lib/erlang",
#       steps: [:assemble, :tar]
#     ]
#   ]
#
# Static ERTS path: ${staticErlang}/lib/erlang
EOF

    runHook postInstall
  '';

  doCheck = false;

  meta = with pkgs.lib; {
    description = "Elixir ${version} with static Erlang/OTP (musl libc)";
    homepage = "https://elixir-lang.org/";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
