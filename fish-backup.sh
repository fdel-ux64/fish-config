#!/usr/bin/env bash
# fish-backup.sh — Fish shell + git repos backup
# Keeps: 3 rolling archives (.tar.zst)
# Log:   1 month retention, pruned in-place
#
# Requires: ~/git/fish-config/conf.d/local/backup-config.env
#   FISH_BACKUP_DEST=/mnt/<your-drive-uuid>

set -euo pipefail

# ─── Load local config ────────────────────────────────────────────────────────
LOCAL_CONFIG="${HOME}/git/fish-config/conf.d/local/backup-config.env"
if [[ ! -f "${LOCAL_CONFIG}" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] Local config not found: ${LOCAL_CONFIG}" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] Create it with: FISH_BACKUP_DEST=/mnt/<uuid>" >&2
    exit 1
fi
# shellcheck source=/dev/null
source "${LOCAL_CONFIG}"

if [[ -z "${FISH_BACKUP_DEST:-}" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] FISH_BACKUP_DEST is not set in ${LOCAL_CONFIG}" >&2
    exit 1
fi

# ─── Configuration ────────────────────────────────────────────────────────────
DEST_MOUNT="${FISH_BACKUP_DEST}"
BACKUP_DIR="${DEST_MOUNT}/fish-backups"
LOG_FILE="${BACKUP_DIR}/fish-backup.log"
KEEP=3
LOG_DAYS=30

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_NAME="fish-backup_${TIMESTAMP}.tar.zst"
ARCHIVE_PATH="${BACKUP_DIR}/${ARCHIVE_NAME}"

# Sources to include
FISH_CONFIG="${HOME}/.config/fish"
GIT_DIR="${HOME}/git"

# ─── Logging ──────────────────────────────────────────────────────────────────
log() {
    local level="$1"
    shift
    local msg="$*"
    local entry="[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${msg}"
    echo "${entry}"
    # Only write to log if BACKUP_DIR exists (post mount-check)
    if [[ -d "${BACKUP_DIR}" ]]; then
        echo "${entry}" >> "${LOG_FILE}"
    fi
}

log_init() {
    # Called after mount + dir checks pass — safe to write
    echo "" >> "${LOG_FILE}"
    echo "════════════════════════════════════════" >> "${LOG_FILE}"
    log INFO "── Backup run started ──────────────────"
}

# ─── Preflight checks ─────────────────────────────────────────────────────────
check_mount() {
    if ! mountpoint -q "${DEST_MOUNT}"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] Destination drive not mounted: ${DEST_MOUNT}" >&2
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] Backup aborted." >&2
        exit 1
    fi
}

check_deps() {
    local missing=()
    for cmd in tar zstd find; do
        command -v "${cmd}" &>/dev/null || missing+=("${cmd}")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] Missing dependencies: ${missing[*]}" >&2
        exit 1
    fi
}

check_sources() {
    local ok=true
    for src in "${FISH_CONFIG}" "${GIT_DIR}"; do
        if [[ ! -d "${src}" ]]; then
            log WARN "Source directory not found, will be skipped: ${src}"
            ok=false
        fi
    done
    if [[ "${ok}" == false ]]; then
        log WARN "Some sources missing — archive may be incomplete"
    fi
}

# ─── Backup dir setup ─────────────────────────────────────────────────────────
ensure_backup_dir() {
    if [[ ! -d "${BACKUP_DIR}" ]]; then
        mkdir -p "${BACKUP_DIR}"
        log INFO "Created backup directory: ${BACKUP_DIR}"
    fi
}

# ─── Log pruning (entries older than LOG_DAYS) ────────────────────────────────
prune_log() {
    if [[ ! -f "${LOG_FILE}" ]]; then
        return
    fi

    local cutoff
    cutoff=$(date -d "${LOG_DAYS} days ago" '+%Y-%m-%d')

    local tmp
    tmp=$(mktemp)

    local pending=()
    local flush=false

    while IFS= read -r line; do
        if [[ "${line}" =~ ^═ ]] || [[ -z "${line}" ]]; then
            pending+=("${line}")
            flush=false
            continue
        fi

        if [[ "${line}" =~ ^\[([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
            local line_date="${BASH_REMATCH[1]}"
            if [[ "${line_date}" < "${cutoff}" ]]; then
                pending=()
                flush=false
                continue
            else
                if [[ "${flush}" == false ]]; then
                    for p in "${pending[@]+"${pending[@]}"}"; do
                        echo "${p}"
                    done
                    pending=()
                    flush=true
                fi
            fi
        fi

        echo "${line}"
    done < "${LOG_FILE}" > "${tmp}"

    mv "${tmp}" "${LOG_FILE}"
    log INFO "Log pruned — kept entries from ${cutoff} onward"
}

# ─── Create archive ───────────────────────────────────────────────────────────
create_archive() {
    local sources=()
    [[ -d "${FISH_CONFIG}" ]] && sources+=("${FISH_CONFIG}")
    [[ -d "${GIT_DIR}" ]]     && sources+=("${GIT_DIR}")

    if [[ ${#sources[@]} -eq 0 ]]; then
        log ERROR "No source directories found — aborting"
        exit 1
    fi

    log INFO "Creating archive: ${ARCHIVE_NAME}"
    log INFO "Sources: ${sources[*]}"

    local rel_sources=()
    for s in "${sources[@]}"; do
        rel_sources+=("${s#/}")
    done

    if tar \
        --use-compress-program="zstd -T0 -3" \
        -cpf "${ARCHIVE_PATH}" \
        -C / \
        --exclude="${GIT_DIR#/}/fish-config/README.private.md" \
        "${rel_sources[@]}" \
        2>&1 | while IFS= read -r line; do log WARN "tar: ${line}"; done; then
        local size
        size=$(du -sh "${ARCHIVE_PATH}" | cut -f1)
        log INFO "Archive created successfully — size: ${size}"
    else
        log ERROR "Archive creation failed"
        rm -f "${ARCHIVE_PATH}"
        exit 1
    fi
}

# ─── Rotate old archives (keep last KEEP) ────────────────────────────────────
rotate_archives() {
    local archives=()
    while IFS= read -r -d '' f; do
        archives+=("${f}")
    done < <(find "${BACKUP_DIR}" -maxdepth 1 -name 'fish-backup_*.tar.zst' -print0 | sort -z)

    local count=${#archives[@]}
    local excess=$(( count - KEEP ))

    if [[ ${excess} -le 0 ]]; then
        log INFO "Archive rotation: ${count}/${KEEP} slots used — nothing to remove"
        return
    fi

    log INFO "Archive rotation: ${count} archives found, removing ${excess} oldest"
    for (( i=0; i<excess; i++ )); do
        log INFO "Removing old archive: $(basename "${archives[$i]}")"
        rm -f "${archives[$i]}"
    done
}

# ─── Summary ──────────────────────────────────────────────────────────────────
print_summary() {
    local archives=()
    while IFS= read -r -d '' f; do
        archives+=("$(basename "${f}")")
    done < <(find "${BACKUP_DIR}" -maxdepth 1 -name 'fish-backup_*.tar.zst' -print0 | sort -z)

    log INFO "── Backup run complete ─────────────────"
    log INFO "Stored archives (${#archives[@]}/${KEEP}):"
    for a in "${archives[@]}"; do
        log INFO "  ${a}"
    done
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    check_deps
    check_mount
    ensure_backup_dir
    log_init
    prune_log
    check_sources
    create_archive
    rotate_archives
    print_summary
}

main "$@"
