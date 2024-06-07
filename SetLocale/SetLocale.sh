#!/bin/bash -e
# https://github.com/massimilianovallascas/anbernic_stockos-apps

current_app_name="SetLocale"
current_path=$(dirname "$0")
current_app_path="${current_path}/${current_app_name}"
log_path="${current_app_path}/log"
now="$(date +'%Y%m%d%H%M%S')"

country_locale_code="en_GB"

function add_timestamp_to_logs() {
    echo -e "\n##### ${now}" >> ${log_path}/dpkg.log
    echo -e "\n##### ${now}" >> ${log_path}/setlocale.log
}

function backup() {
    echo -e "* Backup original files." >> "${log_path}/setlocale.log" 2>&1

    if [ ! -f "/etc/timezone.bkp" ]; then cp /etc/timezone /etc/timezone.bkp; fi
    if [ ! -f "/etc/locale.gen.bkp" ]; then cp /etc/locale.gen /etc/locale.gen.bkp; fi
    if [ ! -f "/etc/default/locale.bkp" ]; then cp /etc/default/locale /etc/default/locale.bkp; fi
}

function restore() {
    echo -e "* Restor original files." >> "${log_path}/setlocale.log" 2>&1

    cp /etc/timezone.bkp /etc/timezone
    cp /etc/locale.gen.bkp /etc/locale.gen
    cp /etc/default/locale.bkp /etc/default/locale
}

function swap_image() {
    local colour="${1}"

    echo -e "* Swap image to ${colour}" >> ${log_path}/setlocale.log
    cp "${current_app_path}/Imgs/setlocale_${colour}.png" "${current_path}/Imgs/SetLocale.png"
}

function main() {
    mkdir -p "${current_app_path}/log"
    add_timestamp_to_logs

    if [ ! -f "${current_app_path}/.updated" ]; then
        echo -e "* Run SetLocale." >> "${log_path}/setlocale.log" 2>&1
        backup
        # Timezone
        echo "Etc/UTC" > /etc/timezone
        dpkg-reconfigure -f noninteractive tzdata >> ${log_path}/dkpg.log

        # Configure locale
        sed -i -e 's/# ${country_locale_code}.UTF-8 UTF-8/${country_locale_code}.UTF-8 UTF-8/' /etc/locale.gen
        echo -e 'LANG="${country_locale_code}.UTF-8"\nLANGUAGE="${country_locale_code}:en"\n' > /etc/default/locale
        dpkg-reconfigure --frontend=noninteractive locales >> ${log_path}/dkpg.log
        update-locale LANG=${country_locale_code}.UTF-8
        touch "${current_app_path}/.updated"
        swap_image green
    else
        echo -e "* Restore SetLocale." >> "${log_path}/setlocale.log" 2>&1
        restore
        dpkg-reconfigure -f noninteractive tzdata >> ${log_path}/dkpg.log
        dpkg-reconfigure --frontend=noninteractive locales >> ${log_path}/dkpg.log
        update-locale LANG=${country_locale_code}.UTF-8
        rm -rf "${current_app_path}/.updated"
        swap_image red
    fi

    sync
    exit 0
}

main
