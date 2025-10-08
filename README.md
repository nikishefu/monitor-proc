# monitor-proc.bash
Simple restart and api failure detector
## Usage: `./monitor-proc.bash [executable_name] [api_url]`
Default values for parameters are defined in the script

## Description:
Periodically checks whether the specified process is running and
whether it's API is available.
Logs process restarts and failed API requests.

### Note:
The script assumes only one instance of the process is running.
If multiple processes share the same executable_name, only the
oldest instance is monitored, which may cause false restart reports.
