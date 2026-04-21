# fgof-temp

Temp files, temp directories, and atomic writes for modern Fortran.

`fgof-temp` is intended to be a small, standalone library for the file-lifecycle
helpers that command-line tools, editors, caches, and test fixtures keep
hand-rolling.

It is part of the [FortranGoingOnForty lib-modules](https://github.com/FortranGoingOnForty/lib-modules)
catalog, but it is intended to stand on its own as a normal `fpm` package.

Current v1 target:

- create temp files and temp directories safely
- expose stable option and resource types
- support atomic write and replace flows
- keep cleanup and ownership rules explicit

Future scope:

- temp worktrees and richer fixture builders
- cache-oriented helpers layered on top
- state persistence helpers built on atomic replace semantics

## Status

Sprint 03 is in place.

Tracked today:

- real temp file and temp directory creation
- text-focused `atomic_write()` and `replace_file()` helpers
- explicit `close_temp()` / `release_temp()` semantics on `temp_resource`
- `temp_guard` ownership-transfer cleanup for grouped resource lifecycles
- tracked examples plus CI coverage for tests and examples

## Why Use It

- temp paths and atomic replace logic show up everywhere in tool code
- most projects still hand-roll cleanup, naming, and safety rules
- a focused library here can become the base for future cache and state packages

## Public API Shape

Primary modules:

- `fgof_temp`
- `fgof_temp_types`

Public types:

- `temp_options`
- `temp_resource`
- `write_result`
- `temp_guard`

Public constants:

- `FGOF_TEMP_OK`
- `FGOF_TEMP_ERR_INVALID_OPTIONS`
- `FGOF_TEMP_ERR_CREATE_FAILED`
- `FGOF_TEMP_ERR_CLEANUP_FAILED`
- `FGOF_TEMP_ERR_WRITE_FAILED`
- `FGOF_TEMP_ERR_REPLACE_FAILED`
- `FGOF_TEMP_ERR_INTERNAL`

Current public procedures:

- `clear_temp_options`
- `clear_temp_resource`
- `make_temp_file`
- `make_temp_dir`
- `cleanup_temp`
- `close_temp`
- `release_temp`
- `clear_write_result`
- `atomic_write`
- `replace_file`
- `clear_temp_guard`
- `register_temp`
- `cleanup_guard`
- `guard_entry_count`
- `temp_backend_name`
- `temp_error_name`

Current semantics:

- `make_temp_file()` creates a real file path and closes the created handle before returning
- `make_temp_dir()` creates a real directory path
- `cleanup_temp()` removes owned resources explicitly
- `close_temp()` respects `cleanup_on_close`: it deletes owned resources when enabled and otherwise just releases ownership
- `release_temp()` leaves the path in place but hands cleanup responsibility back to the caller
- `atomic_write(path, text)` writes through a same-directory temp file and then renames into place
- `replace_file(source, destination)` renames an existing file into place with replacement semantics
- `register_temp()` transfers ownership from a `temp_resource` into a `temp_guard`
- `cleanup_guard()` walks tracked resources in reverse order, which is the safe default for nested temp trees
- temp-file `suffix` is supported
- temp-directory `suffix` is not supported in this first pass and is rejected as invalid options
- `atomic_write()` is text-focused in `v0.1`; it preserves the exact Fortran character payload you pass in

## Build And Test

```bash
fpm test
```

That is the baseline verification command locally and in CI.

Tracked examples:

- [example/atomic_write_demo.f90](/Users/mfwolffe/GithubOrgs/FortranGoingOnForty/fgof-temp/example/atomic_write_demo.f90)
- [example/guard_cleanup_demo.f90](/Users/mfwolffe/GithubOrgs/FortranGoingOnForty/fgof-temp/example/guard_cleanup_demo.f90)

## Supported Platforms

- macOS
- Linux

## Boundaries

- intended to stay independently versioned and releasable
- focused on temp-path and atomic-write ergonomics, not full cache management
- should stay useful on its own even if future packages build on top of it

## License

MIT
