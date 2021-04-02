#!/bin/bash

date2stamp() {
    date --date "$1" +%s
}

prod="$1"
mdc="$2"

if [[ $1 == *.ru ]]
then
  prod="prod2"
elif [[ $1 == *prod3* ]]
then
  prod="prod3"
else
  prod="prod1"
fi

[[ $1 =~ ^(mdc[0-9]*) ]] && mdc="${BASH_REMATCH[1]}" || exit 10

base_path="/opt/logtom/logs/catalina_$prod$mdc"
echo "Base path: $base_path"

current_log="$base_path.log"
last_zipped_log="$(ls -At $base_path*.zip | head -1)"
echo "Current & zipped logs: $current_log, $last_zipped_log"

if [ ! -f $current_log ]
then
  echo "Current tomcat log isn't present on NFS!"
  exit 1
fi

if [[ -z $last_zipped_log || ! -f $last_zipped_log ]]
then
  echo "Zipped tomcat logs are missing from NFS!"
  exit 2
fi

last_zipped_time="$(zless $last_zipped_log | tail -50 | tac | grep -m1 -oP '(?<=^\[)\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}')"
first_time="$(head -10 $current_log | grep -m1 -oP '(?<=^\[)\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}')"
last_time="$(tail -50 $current_log | tac | grep -m1 -oP '(?<=^\[)\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}')"
echo "Last zipped, first, last times: $last_zipped_time, $first_time, $last_time"

last_zipped_timestamp="$(date2stamp "$last_zipped_time")"
first_timestamp="$(date2stamp "$first_time")"
last_timestamp="$(date2stamp "$last_time")"
current_timestamp="$(date2stamp "$(date '+%Y-%m-%d %T')")"

zipped_diff=$((first_timestamp-last_zipped_timestamp))
current_diff=$((current_timestamp-last_timestamp))

echo "zipped: $first_timestamp - $last_zipped_timestamp = $zipped_diff"
echo "current: $current_timestamp - $last_timestamp = $current_diff"

if [ $current_diff -gt 300 ]
then
  echo "Current tomcat log isn't being written to NFS!"
  exit 3
fi

if [ $zipped_diff -gt 300 ]
then
  echo "Last entry in zipped log on NFS is too old!"
  exit 4
fi

echo "OK"
