#!/bin/bash -e
# https://github.com/massimilianovallascas/anbernic_stockos-apps

current_app_name="SSH"
current_path=$(dirname "$0")
current_app_path="${current_path}/${current_app_name}"
log_path="${current_app_path}/log"
now="$(date +'%Y%m%d%H%M%S')"

function add_timestamp_to_logs() {
    echo -e "\n##### ${now}" >> ${log_path}/apt.log
    echo -e "\n##### ${now}" >> ${log_path}/service.log
}

function swap_image() {
    local colour="${1}"

    echo -e "* Swap image to ${colour}" >> ${log_path}/service.log
    cp "${current_app_path}/Imgs/ssh_${colour}.png" "${current_path}/Imgs/SSH.png"
}

function enable_and_start() {
    local isr

    echo -e "* Start SSH service." >> "${log_path}/service.log" 2>&1
    systemctl enable ssh >> "${log_path}/service.log" 2>&1
    systemctl start ssh >> "${log_path}/service.log" 2>&1
    is_running isr
    if (( ${isr} != 0 )); then
        swap_image "green"
    fi
}

function disable_and_stop() {
    local isr

    echo -e "* Stop SSH service." >> "${log_path}/service.log" 2>&1
    systemctl disable ssh >> "${log_path}/service.log" 2>&1
    systemctl stop ssh >> "${log_path}/service.log" 2>&1
    is_running isr
    if (( ${isr} == 0 )); then
        swap_image "red"
    fi
}

function install() {
    echo -e "* Install SSH service." >> "${log_path}/apt.log" 2>&1
    apt update --fix-missing >> "${log_path}/apt.log" 2>&1
    apt install -y openssh-server >> "${log_path}/apt.log" 2>&1
    
    if [ ! -f "${current_app_path}/.first_install" ]; then
        echo "* Backup vendor sshd_config file." >> "${log_path}/service.log" 2>&1
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bkp
        cp /etc/ssh/sshd_config.bkp ${current_app_path}
        cp /etc/ssh/sshd_config ${current_app_path}/sshd_config.current
        touch ${current_app_path}/.first_install
    else
        if [ -f "${current_app_path}/sshd_config" ]; then
            cp ${current_app_path}/sshd_config /etc/ssh/sshd_config
        fi
    fi
}

function is_installed() {
    echo -e "* Check if SSH service is installed." >> "${log_path}/service.log" 2>&1

    local return="${1}"
    local is_installed=$(apt -qq list openssh-server | grep installed | wc -l)

    eval $return="${is_installed}"
}

function is_running() {
    echo -e "* Check if SSH service is running." >> "${log_path}/service.log" 2>&1

    local return="${1}"
    local is_running=$(systemctl --type=service --state=running | grep ssh | wc -l)

    eval $return="${is_running}"
}

function restart() {
    echo -e "* Restart SSH service." >> "${log_path}/service.log" 2>&1

    systemctl restart ssh >> "${log_path}/service.log" 2>&1
}

function purge() {
    echo -e "* Purge SSH service." >> "${log_path}/service.log" 2>&1

    apt purge -y openssh-server >> "${log_path}/service.log" 2>&1
    rm -rf ${current_app_path}/logs/*
    rm -rf ${current_app_path}/.first_install
    swap_image "black"
}

function fix_sudo() {
    echo -e "* Fix sudo." >> "${log_path}/service.log" 2>&1

    chown root:root /usr/bin/sudo && chmod 4755 /usr/bin/sudo
    chown root:root /usr/lib/sudo/sudoers.so && chmod 644 /usr/lib/sudo/sudoers.so
    chown root:root /etc/sudoers && chmod 644 /etc/sudoers
    chown -R root:root /etc/sudoers.d
    chown root:root /etc/sudo.conf && chmod 644 /etc/sudo.conf
}

function main() {
    mkdir -p "${current_app_path}/log"
    add_timestamp_to_logs

    is_installed is_ssh_installed

    if (( ${is_ssh_installed} == 0 )); then
        echo -e "* SSH service not installed." >> "${log_path}/service.log" 2>&1
        install
        enable_and_start
        fix_sudo
    else
        echo -e "* SSH service installed." >> "${log_path}/service.log" 2>&1
        is_running is_ssh_running
        if (( ${is_ssh_running} == 0 )); then
            echo -e "* SSH service not running." >> "${log_path}/service.log" 2>&1
            enable_and_start
        else
            echo -e "* SSH service is running." >> "${log_path}/service.log" 2>&1
            disable_and_stop
        fi
    fi

    sync
    exit 0
}

main
