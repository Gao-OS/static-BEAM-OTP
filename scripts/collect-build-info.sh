#!/bin/bash
# Collect build information from static Erlang installation
# Usage: ./scripts/collect-build-info.sh [erlang_path]
#
# Outputs JSON with:
# - OTP version (accurate from runtime)
# - ERTS version
# - Build configuration
# - Included NIFs
# - Included applications

set -e

ERLANG_PATH="${1:-/opt/erlang}"
ERL_BIN="$ERLANG_PATH/bin/erl"

if [ ! -x "$ERL_BIN" ]; then
  echo "Error: Erlang not found at $ERLANG_PATH" >&2
  exit 1
fi

# Get OTP release version
OTP_RELEASE=$("$ERL_BIN" -noshell -eval 'io:format("~s", [erlang:system_info(otp_release)]), halt().')

# Get ERTS version
ERTS_VERSION=$("$ERL_BIN" -noshell -eval 'io:format("~s", [erlang:system_info(version)]), halt().')

# Get system architecture
SYSTEM_ARCH=$("$ERL_BIN" -noshell -eval 'io:format("~s", [erlang:system_info(system_architecture)]), halt().')

# Get word size
WORD_SIZE=$("$ERL_BIN" -noshell -eval 'io:format("~p", [erlang:system_info(wordsize) * 8]), halt().')

# Get build type
BUILD_TYPE=$("$ERL_BIN" -noshell -eval 'io:format("~s", [erlang:system_info(build_type)]), halt().')

# Get thread support
THREADS=$("$ERL_BIN" -noshell -eval 'io:format("~p", [erlang:system_info(threads)]), halt().')

# Get SMP support
SMP=$("$ERL_BIN" -noshell -eval 'io:format("~p", [erlang:system_info(smp_support)]), halt().')

# Get async threads
ASYNC_THREADS=$("$ERL_BIN" -noshell -eval 'io:format("~p", [erlang:system_info(thread_pool_size)]), halt().')

# Find all NIFs in the installation
NIFS=""
NIF_DIR="$ERLANG_PATH/lib/erlang/lib"
if [ -d "$NIF_DIR" ]; then
  # Find .so files (NIFs) - for static builds these are built-in
  NIFS=$(find "$NIF_DIR" -name "*.so" -type f 2>/dev/null | \
    sed "s|$NIF_DIR/||" | \
    sed 's|/priv/lib/.*||' | \
    sort -u | \
    tr '\n' ',' | \
    sed 's/,$//')
fi

# Get statically linked NIFs from crypto check
CRYPTO_INFO=$("$ERL_BIN" -noshell -eval '
  case code:which(crypto) of
    preloaded -> io:format("preloaded");
    Path when is_list(Path) -> io:format("~s", [Path]);
    _ -> io:format("not_found")
  end,
  halt().' 2>/dev/null || echo "unknown")

# Check which crypto NIFs are available
CRYPTO_NIFS=$("$ERL_BIN" -noshell -eval '
  application:start(crypto),
  Algos = crypto:supports(),
  HashAlgos = proplists:get_value(hashs, Algos, []),
  CipherAlgos = proplists:get_value(ciphers, Algos, []),
  PKAlgos = proplists:get_value(public_keys, Algos, []),
  io:format("hashs:~p,ciphers:~p,public_keys:~p", [length(HashAlgos), length(CipherAlgos), length(PKAlgos)]),
  halt().' 2>/dev/null || echo "unavailable")

# List all available applications
APPLICATIONS=$("$ERL_BIN" -noshell -eval '
  {ok, Apps} = file:list_dir(code:lib_dir()),
  SortedApps = lists:sort([list_to_atom(A) || A <- Apps]),
  AppNames = [begin [Name|_] = string:split(atom_to_list(A), "-"), Name end || A <- SortedApps],
  io:format("~s", [string:join(AppNames, ",")]),
  halt().')

# Check SSL/TLS support
SSL_INFO=$("$ERL_BIN" -noshell -eval '
  application:start(crypto),
  application:start(asn1),
  application:start(public_key),
  application:start(ssl),
  Versions = ssl:versions(),
  Supported = proplists:get_value(supported, Versions, []),
  io:format("~p", [Supported]),
  halt().' 2>/dev/null || echo "[]")

# Output as JSON
cat << EOF
{
  "otp_release": "$OTP_RELEASE",
  "erts_version": "$ERTS_VERSION",
  "system_architecture": "$SYSTEM_ARCH",
  "word_size": $WORD_SIZE,
  "build_type": "$BUILD_TYPE",
  "threads": $THREADS,
  "smp_support": $SMP,
  "async_threads": $ASYNC_THREADS,
  "crypto_support": "$CRYPTO_NIFS",
  "ssl_versions": "$SSL_INFO",
  "applications": "$APPLICATIONS",
  "nif_modules": "$NIFS"
}
EOF
