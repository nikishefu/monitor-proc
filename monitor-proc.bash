#!/usr/bin/env bash
# Usage: ./monitor-proc.bash [executable_name] [api_url]
#   Default values for parameters are defined below
#
# Description:
#   Periodically checks whether the specified process is running and
#   whether it's API is available.
#   Logs process restarts and failed API requests.
#
# Note:
#   The script assumes only one instance of the process is running.
#   If multiple processes share the same executable_name, only the
#   oldest instance is monitored, which may cause false restart reports.

set -euo pipefail
trap 'exit 0' INT TERM

# Parameters default values
executable_name=${1:-test}
api_url=${2:-https://test.com/monitoring/test/api}
log_file="/var/log/monitoring.log"
sleep_time=60

prev_start_time=""
pid_to_monitor=""

log() {
    printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$log_file"
}

get_pid() {
    pgrep -xo "$executable_name" || true
}

check_api() {
    if ! $(curl -sSf $api_url > /dev/null 2> /dev/null); then
        log "API check failed"
    fi
}

# Check whether it was a stop or a restart, log if restart.
proc_stop_or_restart() {
    pid_to_monitor=$(get_pid)
    if [[ -n "$pid_to_monitor" ]]; then
        log "Process restarted"
        check_api
    fi
    start_time=""
    prev_start_time=""
}

while :; do
    # sleep at start of loop to avoid repeating before "continue"
    sleep $sleep_time

    # wait for process to monitor
    if [[ -z $pid_to_monitor ]]; then
        pid_to_monitor=$(get_pid)
        if [[ -z $pid_to_monitor ]]; then
            continue
        fi
    fi

    # if pid+start_time combo changes - process stopped or restarted
    if [[ -r /proc/$pid_to_monitor/stat ]]; then
        start_time=$(awk '{print $22}' "/proc/$pid_to_monitor/stat")
        if [[ -n "$prev_start_time" && "$start_time" != "$prev_start_time" ]]; then
            proc_stop_or_restart
        else
            check_api
        fi
        prev_start_time=$start_time
    else
        proc_stop_or_restart
    fi
done

