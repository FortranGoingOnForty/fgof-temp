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

Sprint 01 is in place.

Tracked today:

- real temp file and temp directory creation
- explicit ownership and cleanup semantics on `temp_resource`
- prefix, suffix, and parent-directory options for temp files
- CI and `fpm test` coverage for creation, cleanup, and option validation

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

Public constants:

- `FGOF_TEMP_OK`
- `FGOF_TEMP_ERR_INVALID_OPTIONS`
- `FGOF_TEMP_ERR_CREATE_FAILED`
- `FGOF_TEMP_ERR_CLEANUP_FAILED`
- `FGOF_TEMP_ERR_INTERNAL`

Current public procedures:

- `clear_temp_options`
- `clear_temp_resource`
- `make_temp_file`
- `make_temp_dir`
- `cleanup_temp`
- `temp_backend_name`
- `temp_error_name`

Current semantics:

- `make_temp_file()` creates a real file path and closes the created handle before returning
- `make_temp_dir()` creates a real directory path
- `cleanup_temp()` removes owned resources explicitly
- temp-file `suffix` is supported
- temp-directory `suffix` is not supported in this first pass and is rejected as invalid options

## Build And Test

```bash
fpm test
```

That is the baseline verification command locally and in CI.

## Supported Platforms

- macOS
- Linux

## Boundaries

- intended to stay independently versioned and releasable
- focused on temp-path and atomic-write ergonomics, not full cache management
- should stay useful on its own even if future packages build on top of it

## License

MIT
