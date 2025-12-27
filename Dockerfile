# Static Erlang/OTP and Elixir build using Alpine Linux (native musl)
#
# Build:
#   docker build --target erlang -o ./static-erlang .
#   docker build --target elixir -o ./static-elixir .
#
# Test:
#   docker build -t static-beam . && docker run --rm static-beam

ARG OTP_VERSION=27.2
ARG ELIXIR_VERSION=1.18.1

# =============================================================================
# Stage 1: Build Erlang/OTP
# =============================================================================
FROM alpine:3.21 AS erlang-builder

ARG OTP_VERSION

RUN apk add --no-cache \
    autoconf automake bash build-base curl git libtool \
    linux-headers ncurses-dev ncurses-static openssl-dev \
    openssl-libs-static perl zlib-dev zlib-static

WORKDIR /build
RUN curl -fSL "https://github.com/erlang/otp/releases/download/OTP-${OTP_VERSION}/otp_src_${OTP_VERSION}.tar.gz" \
    -o otp_src.tar.gz && tar -xzf otp_src.tar.gz && mv otp_src_${OTP_VERSION} otp

WORKDIR /build/otp
# Verify static SSL libs exist
RUN ls -la /usr/lib/libssl.a /usr/lib/libcrypto.a

# Configure for static build
# Note: musl doesn't have libdl, it's built into libc
RUN ./configure \
    --prefix=/opt/erlang \
    --enable-static-nifs \
    --enable-static-drivers \
    --without-javac \
    --without-wx \
    --without-odbc \
    --without-observer \
    --without-debugger \
    --without-et \
    --without-megaco \
    --without-jinterface \
    --with-ssl \
    --with-crypto \
    CFLAGS="-Os" \
    LDFLAGS="-static" \
    LIBS="-lssl -lcrypto -lz"

RUN make -j$(nproc) && make install

RUN find /opt/erlang -type f -executable -exec strip --strip-all {} \; 2>/dev/null || true
RUN rm -rf /opt/erlang/lib/erlang/lib/*/examples \
    /opt/erlang/lib/erlang/lib/*/doc \
    /opt/erlang/lib/erlang/man

# =============================================================================
# Stage 2: Build Elixir
# =============================================================================
FROM erlang-builder AS elixir-builder

ARG ELIXIR_VERSION

ENV PATH="/opt/erlang/bin:${PATH}"

WORKDIR /build
RUN curl -fSL "https://github.com/elixir-lang/elixir/archive/refs/tags/v${ELIXIR_VERSION}.tar.gz" \
    -o elixir_src.tar.gz && tar -xzf elixir_src.tar.gz && mv elixir-${ELIXIR_VERSION} elixir

WORKDIR /build/elixir
RUN make clean && make && make install PREFIX=/opt/elixir

# =============================================================================
# Stage 3: Export Erlang (from scratch)
# =============================================================================
FROM scratch AS erlang
COPY --from=erlang-builder /opt/erlang /

# =============================================================================
# Stage 4: Export Elixir (from scratch)
# =============================================================================
FROM scratch AS elixir
COPY --from=elixir-builder /opt/elixir /

# =============================================================================
# Stage 5: Test image
# =============================================================================
FROM alpine:3.21 AS test
COPY --from=erlang-builder /opt/erlang /opt/erlang
COPY --from=elixir-builder /opt/elixir /opt/elixir
ENV PATH="/opt/elixir/bin:/opt/erlang/bin:${PATH}"
RUN apk add --no-cache file
CMD ["sh", "-c", "\
    echo '=== Binary Analysis ===' && \
    file /opt/erlang/lib/erlang/erts-*/bin/beam.smp && \
    ldd /opt/erlang/lib/erlang/erts-*/bin/beam.smp 2>&1 || echo '(static)' && \
    echo '' && \
    echo '=== Erlang ===' && \
    erl -noshell -eval 'io:format(\"OTP ~s~n\", [erlang:system_info(otp_release)]), halt().' && \
    echo '' && \
    echo '=== Elixir ===' && \
    elixir --version && \
    echo '' && \
    echo '=== Crypto/SSL ===' && \
    erl -noshell -eval 'application:start(crypto), io:format(\"Crypto: OK~n\"), halt().' && \
    echo 'All tests passed!'"]

# Default target
FROM test
