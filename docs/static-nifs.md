# Static NIFs

This repo builds a fully static musl `beam.smp`. Third-party NIFs cannot be
treated like normal Rustler precompiled `.so` artifacts here; they must be
available as static archives and linked into OTP during `./configure`.

OTP supports static NIF archives with this shape:

```sh
./configure --enable-static-nifs=/path/to/libfoo.a:foo
```

For Rustler crates, the static archive also needs a crate-specific NIF init
symbol compatible with OTP's static loader.

## Requested NIFs

| Target | Source | Status |
| --- | --- | --- |
| `denox` | `gsmlg-dev/denox` | Upstream support merged in [gsmlg-dev/denox#5](https://github.com/gsmlg-dev/denox/pull/5), closing [gsmlg-dev/denox#4](https://github.com/gsmlg-dev/denox/issues/4). `main` is bumped to `0.7.0`, builds `native/denox_nif` as both `cdylib` and `staticlib`, exports `denox_nif_nif_init`, and documents `--enable-static-nifs=/path/to/libdenox_nif.a:denox_nif`. Waiting for a `v0.7.0` or newer Denox release with the Linux/musl static artifacts; latest release `v0.6.0` still only publishes dynamic RustlerPrecompiled `.so` archives. |
| `turso` | `gsmlg-dev/ex_turso` | Ready to wire. `v0.4.1` publishes static Linux/musl archives for `x86_64` and `aarch64`; both release tarballs contain `libex_turso.a` and export `ex_turso_nif_init`. [gsmlg-dev/ex_turso#13](https://github.com/gsmlg-dev/ex_turso/issues/13) is closed as completed. |
| `libsql` | `ocean/ecto_libsql` | Publishes Linux musl precompiled dynamic NIFs, but not a static archive suitable for this runtime. |

## Integration Checklist

1. Upstream provides a supported `staticlib` archive for Linux/musl.
2. The archive exposes the NIF init symbol expected by OTP for the library name.
3. `Dockerfile` builds or downloads the archive before OTP configure.
4. OTP configure includes the archive with `--enable-static-nifs=/path/to/libfoo.a:foo`.
5. Runtime tests load the Elixir module and execute at least one local query before the NIF is listed as supported.

References:

- [Erlang `erl_nif` static inclusion documentation](https://www.erlang.org/doc/apps/erts/erl_nif.html)
- [Denox repository](https://github.com/gsmlg-dev/denox)
- [Denox v0.6.0 release artifacts](https://github.com/gsmlg-dev/denox/releases/tag/v0.6.0)
- [Denox static NIF PR](https://github.com/gsmlg-dev/denox/pull/5)
- [ex_turso v0.4.1 release artifacts](https://github.com/gsmlg-dev/ex_turso/releases/tag/v0.4.1)
- [ecto_libsql release artifacts](https://github.com/ocean/ecto_libsql/releases)
