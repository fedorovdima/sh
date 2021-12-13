#!/bin/bash
#
# Checks if Tomcat logs are being written to NFS storage.
# Version: 20210730
#
# For status OK the following conditions should be met:
# 1) last entry in latest zipped log should be older than first entry in current log for no more than 5 mins;
# 2) latest entry in current log should be no older than 5 minutes.
#
# The script is launched by Zabbix item 'Check Tomcat logs',
# key is system.run["/opt/logtom/scripts/check_tomcat_logs.sh {HOST.NAME}"]
# Arguments:
#   Server's hostname. It is passed as {HOST.NAME} by Zabbix.

date2stamp() {
  date --date "$1" +%s
}

err_exit() {
  echo "$2" >&2
  echo -e "$debug"
  exit $1
}

if [[ $1 == *.ru ]]
then
  prod="prod2"
elif [[ $1 == *prod3* ]]
then
  prod="prod3"
else
  prod="prod1"
fi

if [[ $1 =~ ^(mdc[0-9]*) ]]
then
  mdc="${BASH_REMATCH[1]}"
else
  err_exit 1 "Cannot parse node ID from provided hostname!"
fi

debug="---"
base_path="/opt/logtom/logs/catalina_$prod$mdc"
current_log="$base_path.log"
last_zipped_log="$(ls -At $base_path.*.zip | head -1)"
debug="$debug\nCurrent & zipped logs: $current_log, $last_zipped_log"

if [[ ! -r $current_log ]]
then
  err_exit 2 "Current tomcat log is missing from NFS or is unreadable!"
fi

if [[ -z $last_zipped_log || ! -r $last_zipped_log ]]
then
  err_exit 3 "Zipped tomcat logs are missing from NFS!"
fi

max_zipped_size="21000000"  # a bit > 20 Mb
last_zipped_log_size="$(stat -c%s $last_zipped_log)"
zipped_full_scan=false
if [[ $last_zipped_log_size -le $max_zipped_size ]]
then
  zipped_full_scan=true
fi

if [[ "$zipped_full_scan" = true ]]
then
  last_zipped_time="$(zcat $last_zipped_log | tac | grep -m1 -oP '(?<=^\[)\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}')"
else
  last_zipped_time="$(zcat $last_zipped_log | tail -1000 | tac | grep -m1 -oP '(?<=^\[)\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}')"
fi
first_time="$(grep -m1 -oP '(?<=^\[)\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}' $current_log)"
last_time="$(tail -1000 $current_log | tac | grep -m1 -oP '(?<=^\[)\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}')"
debug="$debug\nTimes of latest zipped, first & latest current log entries: $last_zipped_time, $first_time & $last_time"

last_zipped_timestamp="$(date2stamp "$last_zipped_time")"
first_timestamp="$(date2stamp "$first_time")"
last_timestamp="$(date2stamp "$last_time")"
current_timestamp="$(date '+%s')"

zipped_diff=$((first_timestamp-last_zipped_timestamp))
current_diff=$((current_timestamp-last_timestamp))

debug="$debug\nDiff between first entry in current log & latest entry in zipped logs: $first_timestamp - $last_zipped_timestamp = $zipped_diff s"
debug="$debug\nLatest entry in current log: $current_timestamp - $last_timestamp = $current_diff s ago"

if [ $current_diff -gt 300 ]
then
  err_exit 4 "Current tomcat log isn't being written to NFS!"
fi

if [ $zipped_diff -gt 300 ]
then
  err_exit 5 "Latest entry in zipped log on NFS is too old!"
fi

echo "Status: OK"
echo -e "$debug"
