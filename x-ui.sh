#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Loi: ${plain}Vui long chay bang quyen root!\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}He dieu hanh khong duoc ho tro, Vui long su dung he dieu hanh tren he dieu hanh khac!${plain}\n" && exit 1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Vui long su dung he dieu hanh CentOS 7 tro len!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Vui long su dung he dieu hanh Ubuntu 16 tro len!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Vui long su dung he dieu hanh Debian 8 tro len!${plain}\n" && exit 1
    fi
fi

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [默认$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Ban co khoi dong lai bang dieu kien khong? No cung se khoi dong lai xray" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Nhan [ENTER] de quay lai menu chinh: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    confirm "Chuc nang nay se cap nhat phien ban moi nhat, du lieu se khong bi mat. Ban chac chan chu?" "n"
    if [[ $? != 0 ]]; then
        echo -e "${red}Da huy${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
    if [[ $? == 0 ]]; then
        echo -e "${green}Cap nhat thanh cong, dang khoi dong lai bang dieu khien${plain}"
        exit 0
    fi
}

uninstall() {
    confirm "Ban chac chan muon go cai dat chu? No cung se go xray" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop x-ui
    systemctl disable x-ui
    rm /etc/systemd/system/x-ui.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/x-ui/ -rf
    rm /usr/local/x-ui/ -rf

    echo ""
    echo -e "Da go cai dat. Neu ban muon xua menu nay, hay thoat ra va chay lenh ${green}rm /usr/bin/x-ui -f${plain}"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

reset_user() {
    confirm "Ban chac chan muon dat lai tai khoan admin chu" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -username admin -password admin
    echo -e "Tai khoan va mat khau da duoc dat lai thanh admin, vui long khoi dong lai bang dieu khien"
    confirm_restart
}

reset_config() {
    confirm "Ban chac chan muon dat lai bang dieu khien chu, du lieu tai khoan se khong bi xoa!" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -reset
    echo -e "Da dat lai bang dieu khien, truy cap cong ${green}54321${plain} de su dung"
    confirm_restart
}

set_port() {
    echo && echo -n -e "Nhap so cong[1-65535]: " && read port
    if [[ -z "${port}" ]]; then
        echo -e "${yellow}Da huy${plain}"
        before_show_menu
    else
        /usr/local/x-ui/x-ui setting -port ${port}
        echo -e "Sau khi thay doi cong, hay khoi dong lai bang dieu khien va truy cap bang cong ${green}${port}${plain} de su dung"
        confirm_restart
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}Da chay bang dieu, neu muon khoi dong lai hay chon khoi dong lai${plain}"
    else
        systemctl start x-ui
        sleep 3
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}Da khoi dong x-ui${plain}"
        else
            echo -e "${red}Khoi dong that bai, vui long thu lai sau${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        echo -e "${green}Da tat roi, khong the tat tiep${plain}"
    else
        systemctl stop x-ui
        sleep 3
        check_status
        if [[ $? == 1 ]]; then
            echo -e "${green}Da dung x-ui va xray${plain}"
        else
            echo -e "${red}Khong the tat, vui long thu lai sau${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart x-ui
    sleep 3
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}Khoi dong lai thanh cong{plain}"
    else
        echo -e "${red}Khoi dong lai that bai, vui long thu lai sau${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status x-ui -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable x-ui
    if [[ $? == 0 ]]; then
        echo -e "${green}Da dat che do tu dong bat x-ui{plain}"
    else
        echo -e "${red}Cau dat that bai{plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable x-ui
    if [[ $? == 0 ]]; then
        echo -e "${green}Da tat che do tu dong chay x-ui${plain}"
    else
        echo -e "${red}Tat tu dong chay x-ui that bai${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u x-ui.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

migrate_v2_ui() {
    /usr/local/x-ui/x-ui v2-ui

    before_show_menu
}

install_bbr() {
    # temporary workaround for installing bbr
    bash <(curl -L -s https://raw.githubusercontent.com/teddysun/across/master/bbr.sh)
    echo ""
    before_show_menu
}

update_shell() {
    wget -O /usr/bin/x-ui -N --no-check-certificate https://github.com/vaxilu/x-ui/raw/master/x-ui.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}Khong the ket noi toi may chu Github de tai xuong, vui long kien tra ket not internet${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/x-ui
        echo -e "${green}Nang cap x-ui thanh cong, vui long khoi dong lai bang dieu khien${plain}" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/x-ui.service ]]; then
        return 2
    fi
    temp=$(systemctl status x-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled x-ui)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1;
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${red}Da cai dat roi, khong can cai dat tiep${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${red}Vui long cai dat bang dieu khien truoc${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "Trang thai: ${green}Dang chay${plain}"
            show_enable_status
            ;;
        1)
            echo -e "Trang thai: ${yellow}Khong chay${plain}"
            show_enable_status
            ;;
        2)
            echo -e "Trang thai: ${red}Chua cai dat${plain}"
    esac
    show_xray_status
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Tu dong khoi chay: ${green}Co${plain}"
    else
        echo -e "Tu dong khoi chay: ${red}Khong${plain}"
    fi
}

check_xray_status() {
    count=$(ps -ef | grep "xray-linux" | grep -v "grep" | wc -l)
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

show_xray_status() {
    check_xray_status
    if [[ $? == 0 ]]; then
        echo -e "Trang thai xray: ${green}Dang chay${plain}"
    else
        echo -e "Trang thai xray: ${red}Khong chay${plain}"
    fi
}

show_usage() {
    echo "Cach su dung tap lenh quan ly x-ui:"
    echo "----------------------------------------------"
    echo "x-ui              - Mo menu quan ly x-ui"
    echo "x-ui start        - Khoi chay x-ui"
    echo "x-ui stop         - Tam dung x-ui"
    echo "x-ui restart      - Khoi dong lai x-ui"
    echo "x-ui status       - Xem trang thai x-ui"
    echo "x-ui enable       - Tu dong chay x-ui"
    echo "x-ui disable      - Tat tu dong chay x-ui"
    echo "x-ui log          - Xem nhat ky x-ui"
    echo "x-ui v2-ui        - Di chuyen du lieu tu v2-ui sang x-ui"
    echo "x-ui update       - Cap nhat x-ui"
    echo "x-ui install      - Cai dat x-ui"
    echo "x-ui uninstall    - Go cai dat x-ui"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}Bang quan ly x-ui${plain}
  ${green}0.${plain} Thoat
————————————————
  ${green}1.${plain} Cai dat x-ui
  ${green}2.${plain} Cap nhat x-ui
  ${green}3.${plain} Go cai dat x-ui
————————————————
  ${green}4.${plain} Dat lai tai khoan admin
  ${green}5.${plain} Dat lai cai dat
  ${green}6.${plain} Thay doi cong
————————————————
  ${green}7.${plain} Khoi dong x-ui
  ${green}8.${plain} Tam dung x-ui
  ${green}9.${plain} Khoi dong lai x-ui
 ${green}10.${plain} Trang thai x-ui
 ${green}11.${plain} Nhat ky x-ui
————————————————
 ${green}12.${plain} Bat tu dong chay x-ui
 ${green}13.${plain} Tat tu dong chay x-ui
————————————————
 ${green}14.${plain} Tu dong cai dat (New)
 "
    show_status
    echo && read -p "Lua chon [0-14]: " num

    case "${num}" in
        0) exit 0
        ;;
        1) check_uninstall && install
        ;;
        2) check_install && update
        ;;
        3) check_install && uninstall
        ;;
        4) check_install && reset_user
        ;;
        5) check_install && reset_config
        ;;
        6) check_install && set_port
        ;;
        7) check_install && start
        ;;
        8) check_install && stop
        ;;
        9) check_install && restart
        ;;
        10) check_install && status
        ;;
        11) check_install && show_log
        ;;
        12) check_install && enable
        ;;
        13) check_install && disable
        ;;
        14) install_bbr
        ;;
        *) echo -e "${red}Vui long nhap so chinh xac [0-14]${plain}"
        ;;
    esac
}


if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0
        ;;
        "stop") check_install 0 && stop 0
        ;;
        "restart") check_install 0 && restart 0
        ;;
        "status") check_install 0 && status 0
        ;;
        "enable") check_install 0 && enable 0
        ;;
        "disable") check_install 0 && disable 0
        ;;
        "log") check_install 0 && show_log 0
        ;;
        "v2-ui") check_install 0 && migrate_v2_ui 0
        ;;
        "update") check_install 0 && update 0
        ;;
        "install") check_uninstall 0 && install 0
        ;;
        "uninstall") check_install 0 && uninstall 0
        ;;
        *) show_usage
    esac
else
    show_menu
fi
