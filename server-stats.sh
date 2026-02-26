#!/bin/bash

# --- Вспомогательные функции ---
print_header() {
    echo -e "\n\033[1;34m=== $1 ===\033[0m"
}

# --- Обзор системы (Stretch Goals) ---
print_header "System Overview"
echo "macOS Version: $(sw_vers -productVersion) (Build $(sw_vers -buildVersion))"
echo "Uptime:        $(uptime | awk -F', ' '{print $1}' | sed 's/.*up //')"
echo "Load Average:  $(sysctl -n vm.loadavg | awk '{print $2, $3, $4}')"
echo "Logged Users:  $(who | wc -l | xargs)"

# --- Использование CPU ---
# В macOS top выводит idle в конце строки. Считаем: 100 - idle.
print_header "Total CPU Usage"
cpu_idle=$(top -l 1 | grep "CPU usage" | awk '{print $7}' | sed 's/%//')
cpu_usage=$(echo "100 - $cpu_idle" | bc)
echo "Current CPU Usage: ${cpu_usage}%"

# --- Использование памяти ---
# В macOS 'free' отсутствует. Используем vm_stat и переводим страницы в МБ.
print_header "Total Memory Usage"
page_size=$(vm_stat | grep "page size of" | awk '{print $8}')
stats=$(vm_stat)
used_pages=$(echo "$stats" | awk '/Pages active/ {active=$3} /Pages wired/ {wired=$4} END {print active+wired}' | sed 's/\.//')
free_pages=$(echo "$stats" | awk '/Pages free/ {print $3}' | sed 's/\.//')

used_mb=$(echo "$used_pages * $page_size / 1048576" | bc)
free_mb=$(echo "$free_pages * $page_size / 1048576" | bc)
total_mb=$(echo "($used_pages + $free_pages) * $page_size / 1048576" | bc)
usage_pct=$(echo "scale=2; $used_mb / $total_mb * 100" | bc)

echo "Used: ${used_mb}MB | Free: ${free_mb}MB | Usage: ${usage_pct}%"

# --- Использование диска ---
print_header "Total Disk Usage"
df -h / | grep '/' | awk '{
    printf "Used: %s | Free: %s | Usage: %s\n", $3, $4, $5
}'

# --- Топ-5 процессов по CPU ---
print_header "Top 5 Processes by CPU Usage"
ps -Ao pid,ppid,comm,%cpu -r | head -n 6

# --- Топ-5 процессов по памяти ---
print_header "Top 5 Processes by Memory Usage"
ps -Ao pid,ppid,comm,%mem -m | head -n 6

echo -e "\n"
