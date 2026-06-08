#!/bin/sh

# CONFIG
GPG_KEY="zenarmor.asc"
NODE_UUID="latest"

# DEFAULTS
OS_NAME="unknown"
OS_VERSION="unknown"

# ───────────────────────────────
# UTILITY FUNCTIONS

print_logo() {
  echo ''
  echo '     _____ _____  _   _     _     ____   __  __   ___   ____  '
  echo '    |__  /| ____|| \ | |   / \   |  _ \ |  \/  | / _ \ |  _ \ '
  echo '      / / |  _|  |  \| |  / _ \  | |_) || |\/| || | | || |_) |'
  echo '     / /_ | |___ | |\  | / ___ \ |  _ < | |  | || |_| ||  _ < '
  echo '    /____||_____||_| \_|/_/   \_\|_| \_\|_|  |_| \___/ |_| \_\'
  echo ''
}

clear_temp() {
  rm -f /tmp/zenarmor-installer.sh >/dev/null 2>&1 || true
}

print_title() {
  type="$1"
  width=70
  char="-"
  case "$type" in
    error) text="! ERROR !" ;;
    warning) text="! WARNING !" ;;
    success) text="✓ SUCCESS ✓" ;;
    *) text="$type" ;;
  esac
  text_len=${#text}
  padding=$(( (width - text_len) / 2 ))
  left=$(printf '%*s' "$padding" '' | tr ' ' "$char")
  right=$(printf '%*s' "$padding" '' | tr ' ' "$char")
  total=$((padding * 2 + text_len))
  if [ $total -lt $width ]; then
    right="${right}${char}"
  fi
  echo ""
  echo "${left}${text}${right}"
  echo ""
  if [ "$type" = "error" -o "$type" = "warning" ]; then
    clear_temp
  fi
}

check_prerequisites() {
  if [ "$(id -u)" -ne 0 ]; then
    print_title error
    echo "Please run this script as root or with sudo privileges."
    echo ""
    exit 1
  fi
}

detect_os_type() {
  if [ -f /usr/local/sbin/opnsense-version ]; then
    OS_NAME="OPNsense"
    OS_VERSION=$(/usr/local/sbin/opnsense-version -a)
  elif [ -f /etc/os-release ]; then
    OS_NAME=$(grep "^NAME=" /etc/os-release | cut -d= -f2 | tr -d '"')
    OS_VERSION=$(grep "^VERSION_ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
  else
    OS_NAME=$(uname -s 2>/dev/null || echo "unknown")
    OS_VERSION=$(uname -r 2>/dev/null || echo "unknown")
  fi

  [ -z "$OS_NAME" ] && OS_NAME="unknown"
  [ -z "$OS_VERSION" ] && OS_VERSION="unknown"

  ARCH=$(uname -m)
}

log_detected_os() {
  echo ""
  echo "    Detected Operating System"
  echo "    -------------------------"
  echo "    Name    : $OS_NAME       "
  echo "    Version : $OS_VERSION    "
  echo ""
}

set_node_uuid() {
  if [ -f /usr/local/zenarmor/bin/eastpect ]; then
    if [ ! -f /usr/local/zenarmor/etc/serial ]; then
      /usr/local/zenarmor/bin/eastpect -g > /dev/null 2>&1
    fi
    NODE_UUID=$(/usr/local/zenarmor/bin/eastpect -s | tr -d '[:space:]')
    [ -z "$NODE_UUID" ] && NODE_UUID="latest"
  fi
}

warn_pfsense_plus() {
  print_title warning
  echo "Dear valued Zenarmor user,"
  echo ""
  echo "Due to the recent changes to the pfSense+ software;"
  echo "pfSense+ package manager now blocks 3rd party applications"
  echo "from getting installed onto the platform."
  echo ""
  echo "To that end, regretfully, we have decided to remove pfSense+ support."
  echo ""
  echo "If you'd like to continue using Zenarmor,"
  echo "you can consider other platforms alternatives including OPNsense,"
  echo "pfSense CE and other Linux-based distributions."
  echo ""
}

check_pfsense_plus() {
  if [ -f /etc/product_label ]; then
    if grep -iq plus /etc/product_label > /dev/null 2>&1; then
      warn_pfsense_plus
      exit 1
    fi
  fi

  if uname -a | grep -iq plus > /dev/null 2>&1; then
    warn_pfsense_plus
    exit 1
  fi
}

check_freebsd_major_upgrade() {
  if pkg version | grep -q "Major OS version upgrade detected"; then
    print_title warning
    echo "You have a major Operating System upgrade pending."
    echo "Please complete your OS upgrade and try again."
    echo ""
    exit 1
  fi
}

install_opnsense() {
  echo "Installing for OPNsense..."
  touch /tmp/.zenarmor_quick_register > /dev/null 2>&1
  pkg install -fy os-sunnyvalley

  pkg update -f
  pkg install -fy os-sensei os-sensei-agent
  rm -f /tmp/.zenarmor_quick_register > /dev/null 2>&1
  set_node_uuid

}

write_repo_freebsd() {
  set_node_uuid
  if [ "$NODE_UUID" = "latest" ]; then
    REPO_URL="https://updates.zenarmor.net/FreeBSD/\${ABI}"
  else
    REPO_URL="https://updates.zenarmor.net/FreeBSD/\${ABI}/${NODE_UUID}"
  fi

  echo 'SunnyValley: {' > $REPO_CONF_FILE
  echo '  url: "'${REPO_URL}'",' >> $REPO_CONF_FILE
  echo '  priority: 7,' >> $REPO_CONF_FILE
  echo '  enabled: yes' >> $REPO_CONF_FILE
  echo '}' >> $REPO_CONF_FILE
}

install_freebsd() {
  rm -f $REPO_CONF_FILE
  export IGNORE_OSVERSION=yes
  check_freebsd_major_upgrade
  echo "Installing for FreeBSD..."
  mkdir -p /usr/local/etc/pkg/repos/
  rm -f /usr/local/etc/pkg/repos/SunnyValley.conf
  rm -f /usr/local/etc/pkg/repos/Zenarmor.conf
  pkg install -y ca_root_nss
  write_repo_freebsd
  pkg update -f
  touch -f /tmp/.zenarmor_quick_register > /dev/null 2>&1
  pkg install -fy zenarmor
  pkg install -fy zenarmor-agent
  rm -f /tmp/.zenarmor_quick_register > /dev/null 2>&1
  write_repo_freebsd
}

check_redhat_arch() {
  if [ "$ARCH" != "x86_64" -a "$ARCH" != "amd64" ]; then
    print_title error
    echo "This architecture is not yet supported: ($ARCH)"
    echo ""
    exit 0
  fi
}

write_repo_redhat() {
  set_node_uuid
  if [ "$NODE_UUID" = "latest" ]; then
    REPO_URL="https://updates.zenarmor.net/rpm/repo"
  else
    REPO_URL="https://updates.zenarmor.net/rpm/repo/${NODE_UUID}"
  fi

  echo '[zenarmor]' > $REPO_CONF_FILE
  echo 'name=Zenarmor' >> $REPO_CONF_FILE
  echo 'baseurl='${REPO_URL} >> $REPO_CONF_FILE
  echo 'enabled=1' >> $REPO_CONF_FILE
  echo 'gpgcheck=1' >> $REPO_CONF_FILE
}

install_redhat() {
  rm -f $REPO_CONF_FILE
  check_redhat_arch
  echo "Installing for RHEL Family..."
  write_repo_redhat
  rpm --import "https://updates.zenarmor.net/$GPG_KEY"
  dnf install -y glibc libgcc libstdc++ libpcap libmaxminddb libnetfilter_queue libnfnetlink sqlite tinycdb iptables
  touch -f /tmp/.zenarmor_quick_register > /dev/null 2>&1
  dnf install -y zenarmor
  dnf install -y zenarmor-agent
  rm -f /tmp/.zenarmor_quick_register > /dev/null 2>&1
  systemctl daemon-reload
  write_repo_redhat
}

check_debian_arch() {
  if [ "$ARCH" != "x86_64" -a "$ARCH" != "amd64" -a "$ARCH" != "aarch64" -a "$ARCH" != "arm64" ]; then
    print_title error
    echo "This architecture is not yet supported: ($ARCH)"
    echo ""
    exit 0
  fi
}

set_debian_repo_arch() {
  REPO_ARCH="amd64"
  [ "$ARCH" = "aarch64" -o "$ARCH" = "arm64" ] && REPO_ARCH="arm64"
}

set_ubuntu_codename() {
  OS_CODENAME=$(grep "^UBUNTU_CODENAME=" /etc/os-release | cut -d= -f2 | tr -d '"')
  if [ -z "$OS_CODENAME" ]; then
    OS_CODENAME=$(grep "^VERSION_CODENAME=" /etc/os-release | cut -d= -f2 | tr -d '"')
  fi
  if [ -z "$OS_CODENAME" ]; then
    OS_CODENAME=$(grep "^VERSION_ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
  fi
}

write_repo_ubuntu() {
  set_node_uuid
  if [ "$NODE_UUID" = "latest" ]; then
    REPO_URL="https://updates.zenarmor.net/Ubuntu/${OS_CODENAME}/repo"
  else
    REPO_URL="https://updates.zenarmor.net/Ubuntu/${OS_CODENAME}/repo/${NODE_UUID}"
  fi

  echo "deb [arch=${REPO_ARCH}, signed-by=/usr/share/keyrings/zenarmor-repo.gpg] ${REPO_URL} stable main" > $REPO_CONF_FILE
}

install_ubuntu() {
  rm -f $REPO_CONF_FILE
  check_debian_arch
  set_debian_repo_arch
  set_ubuntu_codename
  echo "Installing for Ubuntu..."
  rm -f /etc/apt/sources.list.d/zenarmor.list /usr/share/keyrings/zenarmor-repo.gpg
  apt install -y gpg
  curl -s "https://updates.zenarmor.net/${GPG_KEY}" | gpg --dearmor -o /usr/share/keyrings/zenarmor-repo.gpg
  write_repo_ubuntu
  apt update
  touch -f /tmp/.zenarmor_quick_register > /dev/null 2>&1
  apt --reinstall install -y zenarmor zenarmor-agent
  rm -f /tmp/.zenarmor_quick_register > /dev/null 2>&1
  systemctl daemon-reload
  write_repo_ubuntu
}

write_repo_debian() {
  set_node_uuid
  if [ "$NODE_UUID" = "latest" ]; then
    REPO_URL="https://updates.zenarmor.net/Debian/${OS_VERSION}/repo"
  else
    REPO_URL="https://updates.zenarmor.net/Debian/${OS_VERSION}/repo/${NODE_UUID}"
  fi

  echo "deb [arch=${REPO_ARCH}, signed-by=/usr/share/keyrings/zenarmor-repo.gpg] ${REPO_URL} stable main" > $REPO_CONF_FILE
}

install_debian() {
  rm -f $REPO_CONF_FILE
  check_debian_arch
  set_debian_repo_arch
  echo "Installing for Debian..."
  apt -y install apt-transport-https gnupg
  rm -f /etc/apt/sources.list.d/zenarmor.list /usr/share/keyrings/zenarmor-repo.gpg
  apt install -y gpg
  wget -qO- "https://updates.zenarmor.net/$GPG_KEY" | gpg --dearmor -o /usr/share/keyrings/zenarmor-repo.gpg
  write_repo_debian
  apt update
  touch -f /tmp/.zenarmor_quick_register > /dev/null 2>&1
  apt --reinstall install -y zenarmor zenarmor-agent
  rm -f /tmp/.zenarmor_quick_register > /dev/null 2>&1
  systemctl daemon-reload
  write_repo_debian
}

detect_openwrt_package_manager() {
  OPENWRT_PKG_MANAGER="opkg"
  OPENWRT_PKG_ACTION="install"
  REPO_CONF_FILE="/etc/opkg/zenarmor.conf"
  if command -v apk >/dev/null 2>&1; then
    OPENWRT_PKG_MANAGER="apk"
    OPENWRT_PKG_ACTION="add"
    REPO_CONF_FILE="/etc/apk/repositories.d/zenarmor.list"
  fi
}

check_openwrt_wget() {
  if ! command -v wget >/dev/null 2>&1; then
    $OPENWRT_PKG_MANAGER update
    $OPENWRT_PKG_MANAGER $OPENWRT_PKG_ACTION wget
    if ! command -v wget >/dev/null 2>&1; then
      print_title error
      echo "wget command not found and installation failed."
      echo "Please install it manually and try again."
      echo ""
      exit 1
    fi
  fi
}

fetch_repo_key_openwrt() {
  if [ "$OPENWRT_PKG_MANAGER" = "opkg" ]; then
    wget https://updates.zenarmor.net/openwrt/openWrtZenarmorUsign.pub

    if [ ! -f openWrtZenarmorUsign.pub ]; then
      print_title error
      echo "Failed to download 'openWrtZenarmorUsign.pub' file."
      echo "Please check your internet connection and try again."
      echo ""
      exit 1
    fi
    opkg-key add openWrtZenarmorUsign.pub
  elif [ "$OPENWRT_PKG_MANAGER" = "apk" ]; then
    wget https://updates.zenarmor.net/openwrt/openWrtZenarmorApkUsign.rsa.pub

    if [ ! -f openWrtZenarmorApkUsign.rsa.pub ]; then
      print_title error
      echo "Failed to download 'openWrtZenarmorApkUsign.rsa.pub' file."
      echo "Please check your internet connection and try again."
      echo ""
      exit 1
    fi
    cp openWrtZenarmorApkUsign.rsa.pub /etc/apk/keys/
  fi
}

write_repo_openwrt() {
  set_node_uuid
  rm -f $REPO_CONF_FILE
  if [ "$OPENWRT_PKG_MANAGER" = "opkg" ]; then
    echo "src/gz zenarmor https://updates.zenarmor.net/openwrt/${OS_VERSION:0:5}/${OPENWRT_ARCH}" > $REPO_CONF_FILE

  elif [ "$OPENWRT_PKG_MANAGER" = "apk" ]; then
    echo "https://updates.zenarmor.net/openwrt/${OS_VERSION:0:5}/${OPENWRT_ARCH}/packages.adb" > $REPO_CONF_FILE

  fi
}

install_openwrt() {
  detect_openwrt_package_manager
  check_openwrt_wget
  fetch_repo_key_openwrt
  write_repo_openwrt
  $OPENWRT_PKG_MANAGER update
  $OPENWRT_PKG_MANAGER $OPENWRT_PKG_ACTION libpcap iptables ip6tables openssl-util libnetfilter-queue iptables-mod-nfqueue \
    kmod-nfnetlink-queue coreutils-timeout kmod-tun ip-full bash coreutils-env sqlite3-cli
  if [ "${OPENWRT_ARCH}" = "x86_64" ];then
    $OPENWRT_PKG_MANAGER $OPENWRT_PKG_ACTION libstdcpp6
  fi
  touch -f /tmp/.zenarmor_quick_register > /dev/null 2>&1
  $OPENWRT_PKG_MANAGER $OPENWRT_PKG_ACTION zenarmor zenarmor-agent
  rm -f /tmp/.zenarmor_quick_register > /dev/null 2>&1
  write_repo_openwrt
}

# ───────────────────────────────
# MAIN EXECUTION

print_logo
check_prerequisites
detect_os_type
log_detected_os

case "$OS_NAME" in
  "OPNsense")
    REPO_CONF_FILE="/usr/local/etc/pkg/repos/SunnyValley.conf"
    install_opnsense
    ;;
  "FreeBSD")
    check_pfsense_plus
    REPO_CONF_FILE="/usr/local/etc/pkg/repos/Zenarmor.conf"
    install_freebsd
    ;;
  "CentOS Linux"|"CentOS Stream"|"AlmaLinux"|"ClearOS"|"Rocky Linux"|"Red Hat Enterprise Linux"|"Amazon Linux"|"Fedora Linux")
    REPO_CONF_FILE="/etc/yum.repos.d/zenarmor.repo"
    install_redhat
    ;;
  "Ubuntu"|"Linux Mint")
    REPO_CONF_FILE="/etc/apt/sources.list.d/zenarmor.list"
    install_ubuntu
    ;;
  "Debian GNU/Linux 12 (bookworm)"|"Debian GNU/Linux 11 (bullseye)"|"Debian GNU/Linux")
    REPO_CONF_FILE="/etc/apt/sources.list.d/zenarmor.list"
    install_debian
    ;;
  "OpenWrt")
    OPENWRT_ARCH=`cat /etc/os-release | grep "OPENWRT_ARCH" | head -1 | awk -F"=" '{print $2}' | sed -e 's/"//g'`
    install_openwrt
    ;;
  *)
    print_title error
    echo "Unsupported OS: $OS_NAME"
    echo ""
    exit 1
    ;;
esac

if [ ! -f /usr/local/zenarmor/bin/eastpect ] || [ ! -f /usr/local/zenarmor/zenarmor-agent/bin/zenarmor-agent ]; then
  print_title error
  echo "The installation could not be completed successfully."
  echo ""
  echo "Please make sure your operating system is supported,"
  echo "and that you have a stable internet connection, then try again."
  echo ""
  exit 1
fi

print_title success
echo "Installation finished successfully."
echo ""

echo "Registering your firewall gateway to Zenconsole Cloud Management Portal..."
echo ""

if [ "$OS_NAME" = "OPNsense" ]; then
  /usr/local/zenarmor/zenarmor-agent/bin/zenarmor-agent -qr BluPjEjstj -source opnsense_wizard
  REGISTER_SUCCESS=$?
  /usr/local/sbin/zenarmorctl cloud start
else
  /usr/local/zenarmor/zenarmor-agent/bin/zenarmor-agent -qr BluPjEjstj
  REGISTER_SUCCESS=$?
fi

if [ "$OS_NAME" = "OpenWrt" ]; then
  /etc/init.d/zenarmor-agent restart
fi

if [ $REGISTER_SUCCESS -eq 0 ]; then
  print_title success
  echo "Registration to Zenconsole completed successfully."
  echo "Starting zenarmor-agent service now..."
  sleep 3
  echo "Zenarmor agent started, Zenconsole communication is online!"
  echo ""
  echo "Please return to Zenconsole and complete the gateway provisioning process."
  echo "You should be able see your new gateway popping up under “Pending Gateways”."
  echo "After completing the initial configuration wizard,"
  echo "your new gateway will be fully operational."
  echo ""
else
  print_title error
  echo "Registration to Zenconsole was unsuccessful."
  echo "Please verify that your internet connection is stable,"
  echo "and that the installation script is valid, then try again."
  echo ""
fi

