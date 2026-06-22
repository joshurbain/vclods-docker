# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Layout

This repo is a Docker wrapper around the [VCLODs framework](https://github.com/cstobey/vclods), which lives as a git submodule at `./vclods/`.

```
./Dockerfile          # OracleLinux 8 image; installs ksh, mysql, mssql-tools (amd64 only), Oracle client (amd64 only)
./docker-entrypoint.sh # Writes /etc/vclods from env vars at container start, then drops to bash
./full_build.sh       # Convenience: rm old container → build → run → exec shell
./scripts/            # Bind-mounted to /app/scripts inside the container; put user scripts here
./oracle_config/      # Bind-mounted to /app/oracle_config; place Oracle TNS files here
./vclods/             # Git submodule — the actual VCLODs framework (ksh scripts, extensions, tests)
```

## Common Commands

### Build and run the container

```bash
# Full cycle (removes prior container, builds, runs, opens shell)
./full_build.sh                     # default name "vclod", auto-detect arch
./full_build.sh myname arm64        # named container, force arm64

# Manual steps
docker rm -f -v vclod
docker build --tag vclods:1.0 .
docker container run -i -t -d \
  -v $(realpath ./scripts):/app/scripts \
  -v $(realpath ./oracle_config):/app/oracle_config \
  --name vclod vclods:1.0

docker exec -it vclod /bin/bash
```

### Override connection config at runtime

```bash
docker container run ... \
  -e VCLOD_ENGINE=mssql \
  -e VCLOD_HOST=my-sql-server \
  -e VCLOD_USER=sa \
  -e VCLOD_PASSWORD=secret \
  -e VCLOD_DB=mydb \
  --name vclod vclods:1.0
```

The entrypoint writes these into `/etc/vclods` so all VCLODs scripts pick them up automatically.

### Run VCLODs scripts (inside the container)

```bash
vclod /path/to/script.sh           # run a single script
vclod /path/to/directory/          # run all scripts in a directory recursively
O_VCLOD_HOST=other-host vclod script.sql  # override any config var with O_ prefix
vsql                               # interactive SQL on the SRC connection
vdst                               # interactive SQL on the DST connection
vps                                # view running VCLODs processes
vkill <pid>                        # kill a VCLODs process tree
```

### Run tests (inside the container or with ksh)

```bash
# From /app (the vclods submodule root inside the container):
./run_tests.sh                     # full test suite
./run_tests.sh vclod_dir/some_test.sh  # run a single test, show output
```

Tests require `./test/secure_config` to be populated with `VCLOD_MYSQL_HOST`, `VCLOD_MYSQL_USER`, `VCLOD_MYSQL_PASSWORD`, and `LOG_SQL_HOST`.

## Architecture: How VCLODs Works

VCLODs uses **filename extensions as a pipeline language**. Extensions are read **right-to-left** like shell pipes. Each extension processes the stdout of the previous one.

- `script.sh` — run as a ksh script
- `script.sql` — send as SQL to the SRC connection
- `script.sql.sh` — run `.sh`, pipe stdout as SQL to SRC connection
- `script.dst.sql` — run SQL on SRC, pipe output as SQL to DST connection (data migration)
- `script.err.diff-file.*` — run something, compare with a file, treat diff as an error

Extension implementations live in `vclods/extensions/`. Each extension is a ksh script.

### Configuration hierarchy

1. `/etc/vclods` — global config (written by `docker-entrypoint.sh` from env vars)
2. Per-directory `config` file — overrides globals for all scripts in that directory
3. `O_VARNAME=value` prefix on the command line — overrides everything

### Connection variable resolution

`.sql` uses the `SRC` prefix (default `VCLOD_SRC_`); `.dst` uses the `DST` prefix (default `VCLOD_DST_`). If `VCLOD_SRC_HOST` is unset, VCLODs falls back to `VCLOD_MYSQL_HOST` (engine-specific), then `VCLOD_HOST`. Supported engines: `mysql`, `mssql`, `mssql` (amd64 only), `oracle` (amd64 only), `postgres`.

### Locking

Each script automatically prevents concurrent duplicate execution. Lock files live in `$VCLOD_LOCK_DIR` (defaults to `/dev/shm/`). Symlinks are treated as distinct scripts, so the same script can run with different configs simultaneously.

### Logging / output destinations

All stdout at the end of the extension pipe goes to log files (`$LOG_BASE_DIR`) and syslog. Stderr goes to `$OPERATIONS_EMAIL` and optionally Slack. Logs can also be stored in a SQL database by configuring `LOG_SQL_*` variables and loading `pp_log2sql_table.sql`.

## Platform Notes

- **amd64 only**: `mssql-tools` (sqlcmd) and Oracle Instant Client are not installed on arm64 builds.
- `VCLOD_USE_CGROUP=0` is hardcoded in `docker-entrypoint.sh` — cgroups are disabled in the Docker environment.
- `LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN=y` is set for legacy MySQL auth compatibility.
