#!/usr/bin/env bash

function getIPAddress() {
    local ip_route
    ip_route=$(ip -4 route get 8.8.8.8 2>/dev/null)
    if [[ -z "$ip_route" ]]; then
        ip_route=$(ip -6 route get 2001:4860:4860::8888 2>/dev/null)
    fi
    [[ -n "$ip_route" ]] && grep -oP "src \K[^\s]+" <<< "$ip_route"
}

function rpi_welcome() {
    local upSeconds="$(/usr/bin/cut -d. -f1 /proc/uptime)"
    local secs=$((upSeconds%60))
    local mins=$((upSeconds/60%60))
    local hours=$((upSeconds/3600%24))
    local days=$((upSeconds/86400))
    local UPTIME=$(printf "%d days, %02dh%02dm%02ds" "$days" "$hours" "$mins" "$secs")

    # calculate rough CPU and GPU temperatures:sudo
    local cpuTempC
    local cpuTempF
    local gpuTempC
    local gpuTempF
    if [[ -f "/sys/class/thermal/thermal_zone0/temp" ]]; then
        cpuTempC=$(($(cat /sys/class/thermal/thermal_zone0/temp)/1000)) && cpuTempF=$((cpuTempC*9/5+32))
    fi

    if [[ -f "/usr/bin/vcgencmd" ]]; then
        if gpuTempC=$(/usr/bin/vcgencmd measure_temp); then
            gpuTempC=${gpuTempC:5:2}
            gpuTempF=$((gpuTempC*9/5+32))
        else
            gpuTempC=""
        fi
    fi

    local df_out=()
    local line
    while read line; do
        df_out+=("$line")
    done < <(df -h /)

    local rst="$(tput sgr0)"
    local fgblk="${rst}$(tput setaf 0)" # Black - Regular
    local fgred="${rst}$(tput setaf 1)" # Red
    local fggrn="${rst}$(tput setaf 2)" # Green
    local fgylw="${rst}$(tput setaf 3)" # Yellow
    local fgblu="${rst}$(tput setaf 4)" # Blue
    local fgpur="${rst}$(tput setaf 5)" # Purple
    local fgcyn="${rst}$(tput setaf 6)" # Cyan
    local fgwht="${rst}$(tput setaf 7)" # White

    local bld="$(tput bold)"
    local bfgblk="${bld}$(tput setaf 0)"
    local bfgred="${bld}$(tput setaf 1)"
    local bfggrn="${bld}$(tput setaf 2)"
    local bfgylw="${bld}$(tput setaf 3)"
    local bfgblu="${bld}$(tput setaf 4)"
    local bfgpur="${bld}$(tput setaf 5)"
    local bfgcyn="${bld}$(tput setaf 6)"
    local bfgwht="${bld}$(tput setaf 7)"

    local logo=(
        "${fggrn}                  "
        "${fggrn}   .~~.   .~~.    "
        "${fggrn}  '. \ ' ' / .'   "
        "${fgred}   .~ .~~~..~.    "
        "${fgred}  : .~.'~'.~. :   "
        "${fgred} ~ (   ) (   ) ~  "
        "${fgred}( : '~'.~.'~' : ) "
        "${fgred} ~ .~ (   ) ~. ~  "
        "${fgred}  (  : '~' :  )   "
        "${fgred}   '~ .~~~. ~'    "
        "${fgred}       '~'        "
        "${fgred}                  "
        )

    local out
    local i
    for i in "${!logo[@]}"; do
        out+="  ${logo[$i]}  "
        case "$i" in
            0)
                out+="${fgcyn}$(date +"%A, %e %B %Y, %H:%M:%S")"
                ;;
            1)
                out+="${fgcyn}$(uname -srmo)"
                ;;
            3)
                out+="${fgylw}${df_out[0]}"
                ;;
            4)
                out+="${fgwht}${df_out[1]}"
                ;;
            5)
                out+="${fgred}Uptime.............:""${fgwht} ${UPTIME}"
                ;;
            6)
                out+="${fgred}Memory.............:""${fgwht} $(free -m | awk 'NR==2 { printf "Total: %sMB, Used: %sMB, Free: %sMB",$2,$3,$4; }')"
                ;;
            7)
                out+="${fgred}Disk Usage... .....:""${fgwht} $(df -h ~ | awk 'NR==2 { printf "Total: %sB, Used: %sB, Free: %sB",$2,$3,$4; }')"
                ;;
            8)
                out+="${fgred}Running Processes..:""${fgwht} $(ps ax | wc -l | tr -d " ")"
                ;;
            9)
                out+="${fgred}IP Address.........: $(getIPAddress)"
                ;;
            10)
                out+="Temperature........: CPU: ${cpuTempC}°C/${cpuTempF}°F GPU: ${gpuTempC}°C/${gpuTempF}°F"
                ;;
            11)
                out+="${fgblu}Raspberry PI Foundation, https://www.raspberrypi.org/"
                ;;
        esac
        out+="\n"
    done
    echo -e "\n$out"
}

rpi_welcome
