#!/bin/bash
#
ver="1.00"
cpu_warning=90
cpu_critical=95
ram_warning=101
ram_critical=102
disk_free_warning=10
disk_free_critical=5
disk_use_warning=90
disk_use_critical=95

# volume usage percent (bigger)
vol_use=`iostat -d -N -x -y 1 1 | sed '/^\s*$/d'| awk '{print $16}' | grep -v %util | sort | tail -1`
vol_use=`printf "%.0f\n" $vol_use`
#echo "Disk use: $vol_use"


# volume free (less)
vol_free=`df | awk '{print $5}' | cut -d'%' -f1 | sort | grep [0-9] | tail -1`
vol_free=$((100-vol_free))
#echo "Disk free: $vol_free"

#uptime days
uptime_sec=`cat /proc/uptime | awk -F' ' '{print $1}' | awk -F'.' '{print $1}'`
uptime_days="$((uptime_sec / 60 / 60 / 24))"
#echo "Node uptime: $uptime_days"

# CPU usage percent
cpu_use=`mpstat | awk '$12 ~ /[0-9.]+/ { print 100 - $12 }'`
#echo "CPU use: $cpu_use"

# RAM usage percent
ram_use_percent=`free | grep -v \t | awk '{print $3/$2 * 100.0}' | sort -n | tail -1 | cut -d'.' -f1`
#echo "Node RAM use: $ram_use_percent"

url="http://10.59.20.16:8000"
mess=${HOSTNAME}" /"
stat=0

# 1.CPU
if [[ $cpu_use -ge $cpu_critical ]]
then
  stat=2
  mess=$mess' !!!CPU:'$cpu_use
else
  if [[ $cpu_use -ge $cpu_warning ]]
  then
    if [[ $stat -eq 0 ]]
    then
      stat=1
    fi
    mess=$mess' !CPU:'$cpu_use
  else
    mess=$mess' CPU:'$cpu_use
  fi
fi

# 2.RAM
if [[ $ram_use_percent -ge $ram_critical ]]
then
  stat=2
  mess=$mess' !!!RAM:'$ram_use_percent
else
  if [[ $ram_use_percent -ge $ram_warning ]]
  then
    if [[ $stat -eq 0 ]]
    then
      stat=1
    fi
    mess=$mess' !RAM:'$ram_use_percent
  else
    mess=$mess' RAM:'$ram_use_percent
  fi
fi

# 3.Disk_free
if [[ $vol_free -lt $disk_free_critical ]]
then
  stat=2
  mess=$mess' !!!Disk_free:'$vol_free
else
  if [[ $vol_free -lt $disk_free_warning ]]
  then
    if [[ $stat -eq 0 ]]
    then
      stat=1
    fi
    mess=$mess' !Disk_free:'$vol_free
  else
    mess=$mess' Disk_free:'$vol_free
  fi
fi

# 4.Disk_use
if [[ $vol_use -ge $disk_use_critical ]]
then
  stat=2
  mess=$mess' !!!Disk_use:'$vol_use
else
  if [[ $vol_use -ge $disk_use_warning ]]
  then
    if [[ $stat -eq 0 ]]
    then
      stat = 1
    fi
    mess=$mess' !Disk_use:'$vol_use
  else
    mess=$mess' Disk_use:'$vol_use
  fi
fi

# 5.Uptime
mess=$mess' Uptime:'$uptime_days

# 6.Version
mess=$mess' ver:'$ver

case $stat in
  2)
    mess='fed-hw;STAT_'${HOSTNAME}';2;CRITICAL-'$mess' / upd:'$(date  +%d.%m.%Y\ %H:%M:%S);;
  1)
    mess='fed-hw;STAT_'${HOSTNAME}';1;WARNING-'$mess' / upd:'$(date  +%d.%m.%Y\ %H:%M:%S);;
  0)
    mess='fed-hw;STAT_'${HOSTNAME}';0;OK-'$mess' / upd:'$(date  +%d.%m.%Y\ %H:%M:%S);;
  *)
    mess='fed-hw;STAT_'${HOSTNAME}';3;UNKNOWN-'$mess' / upd:'$(date  +%d.%m.%Y\ %H:%M:%S)
esac

mess=$mess" | 'CPU'="$cpu_use"%;"$cpu_warning";"$cpu_critical";0;100 'RAM'="$ram_use_percent"%;"$ram_warning";"$ram_critical";0;100 'Disk_free'="
mess=$mess$vol_free"%;"$disk_free_warning";"$disk_free_critical";0;100 'Disk_use'="$vol_use"%;"$disk_use_warning";"$disk_use_critical";0;100 'Uptime'="$uptime_days";;;;"

curl \
  --request "POST" \
  --user 'fed_monitor:l3tm31n' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode "perfdata=$mess" \
  --url $url

#echo -----------------------------------------------------------------------------------
#echo $mess
#echo $resp