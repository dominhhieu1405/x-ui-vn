#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

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

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
  arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
  arch="arm64"
else
  arch="amd64"
  echo -e "${red}Khong phat hien duoc kien ​​truc, hay su dung kien ​​truc mac dinh${arch}${plain}"
fi

echo "Kien truc: ${arch}"

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ] ; then
    echo "Chuong trinh nay khong ho tro he thong 32-bit (x86), Vui long su dung he dieu hanh he thong 64-bit (x86_64)"
    exit -1
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

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
    fi
}

install_x-ui() {
    #systemctl stop x-ui
    cd /usr/local/

    if  [ $# == 0 ] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/dominhhieu1405/x-ui-vn/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}Khong the phat hien phien ban x-ui, phien ban nay co the vuot qua gioi han API Github, vui long thu lai sau hoac chi dinh phien ban x-ui de cai dat theo cach thu cong${plain}"
            exit 1
        fi
        echo -e "Phien ban moi nhat cua x-ui: ${last_version}, dang cai dat..."
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz https://github.com/dominhhieu1405/x-ui-vn/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Tai xuong x-ui khong thanh cong, vui long dam bao may chu cua ban co the tai xuong tep tu Github${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/dominhhieu1405/x-ui-vn/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz"
        echo -e "Bat dau cai dat x-ui v$1"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Tai x-ui khong thanh cong, phien ban nay co the da bi xoa hoac khong ton tai${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux-${arch}.tar.gz
    rm x-ui-linux-${arch}.tar.gz -f
    cd x-ui
    chmod +x x-ui bin/xray-linux-${arch}
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/dominhhieu1405/x-ui-vn/main/x-ui.sh
    chmod +x /usr/bin/x-ui
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "${green}x-ui v${last_version}${plain} cai dat thanh cong, dang bat dau bang dieu khien"
    echo -e ""
    echo -e "Neu cai moi, cong web mac dinh la ${green}54321${plain}, tai khoan va mat khau mac dinh la ${green}admin${plain}"
    echo -e "Hay dam bao cong nay chua duoc su dung, ${yellow}va cong 54321 duoc mo cong khai${plain}"
#    echo -e "Neu ban muon thay cong 54321 bang mot cong khac, hay dam bao no chua duoc su dung va dung lenh x-ui de doi thay doi"
    echo -e ""
    echo -e "Neu ban cap nhat bang dieu khien, hay truy cap nhu ban da lam truoc day"
    echo -e ""
    echo -e "Cach su dung tap lenh quan ly x-ui:"
    echo -e "----------------------------------------------"
    echo -e "x-ui              - Mo menu quan ly x-ui"
    echo -e "x-ui start        - Khoi chay x-ui"
    echo -e "x-ui stop         - Tam dung x-ui"
    echo -e "x-ui restart      - Khoi dong lai x-ui"
    echo -e "x-ui status       - Xem trang thai x-ui"
    echo -e "x-ui enable       - Tu dong chay x-ui"
    echo -e "x-ui disable      - Tat tu dong chay x-ui"
    echo -e "x-ui log          - Xem nhat ky x-ui"
    echo -e "x-ui v2-ui        - Di chuyen du lieu tu v2-ui sang x-ui"
    echo -e "x-ui update       - Cap nhat x-ui"
    echo -e "x-ui install      - Cai dat x-ui"
    echo -e "x-ui uninstall    - Go cai dat x-ui"
    echo -e "----------------------------------------------"
}

echo -e "${green}Bat dau cai dat${plain}"
install_base
install_x-ui $1
