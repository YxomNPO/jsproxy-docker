#!/usr/bin/env bash

{ # this ensures the entire script is downloaded #

JSPROXY_VER=0.1.0
OPENRESTY_VER=1.15.8.1

SRC_URL=https://raw.githubusercontent.com/EtherDream/jsproxy/$JSPROXY_VER
BIN_URL=https://raw.githubusercontent.com/EtherDream/jsproxy-bin/master
ZIP_URL=https://codeload.github.com/EtherDream/jsproxy/tar.gz

SUPPORTED_OS="Linux-x86_64"
OS="$(uname)-$(uname -m)"
USER=$(whoami)

INSTALL_DIR=/home/jsproxy
NGX_DIR=$INSTALL_DIR/openresty

DOMAIN_SUFFIX=(
  xip.io
  nip.io
  sslip.io
)

GET_IP_API=(
  https://api.ipify.org
  https://bot.whatismyipaddress.com/
)

COLOR_RESET="\033[0m"
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"

output() {
  local color=$1
  shift 1
  local sdata=$@
  local stime=$(date "+%H:%M:%S")
  printf "$color[jsproxy $stime]$COLOR_RESET $sdata\n"
}
log() {
  output $COLOR_GREEN $1
}
warn() {
  output $COLOR_YELLOW $1
}
err() {
  output $COLOR_RED $1
}

install() {
  cd $INSTALL_DIR

  log "下载 nginx 程序 ..."
  curl -O $BIN_URL/$OS/openresty-$OPENRESTY_VER.tar.gz
  tar zxf openresty-$OPENRESTY_VER.tar.gz
  rm -f openresty-$OPENRESTY_VER.tar.gz

  local ngx_exe=$NGX_DIR/nginx/sbin/nginx
  local ngx_ver=$($ngx_exe -v 2>&1)

  if [[ "$ngx_ver" != *"nginx version:"* ]]; then
    err "$ngx_exe 无法执行！尝试编译安装"
    exit 1
  fi
  log "$ngx_ver"
  log "nginx path: $NGX_DIR"

  log "下载代理服务 ..."
  curl -o jsproxy.tar.gz $ZIP_URL/$JSPROXY_VER
  tar zxf jsproxy.tar.gz
  rm -f jsproxy.tar.gz

  log "下载静态资源 ..."
  curl -o www.tar.gz $ZIP_URL/gh-pages
  tar zxf www.tar.gz -C jsproxy-$JSPROXY_VER/www --strip-components=1
  rm -f www.tar.gz

  if [ -x server/run.sh ]; then
    warn "尝试停止当前服务 ..."
    server/run.sh quit
  fi

  if [ -d server ]; then
    local backup="$INSTALL_DIR/bak/$(date +%Y_%m_%d_%H_%M_%S)"
    warn "当前 server 目录备份到 $backup"
    mkdir -p $backup
    mv server $backup
  fi

  mv jsproxy-$JSPROXY_VER server

  log "启动服务 ..."
  server/run.sh

  log "服务已开启"
  
  shift 1
}

main() {
  log "自动安装脚本开始执行"

  if [[ "$SUPPORTED_OS" != *"$OS"* ]]; then
    err "当前系统 $OS 不支持自动安装。尝试编译安装"
    exit 1
  fi

  if [[ "$USER" != "root" ]]; then
    err "自动安装需要 root 权限。如果无法使用 root，尝试编译安装"
    exit 1
  fi

  local cmd
  if [[ $0 == *"i.sh" ]]; then
    warn "本地调试模式"

    local dst=/home/jsproxy/i.sh
    cp $0 $dst
    chown jsproxy:nobody $dst
    if [[ $1 == "-s" ]]; then
      shift 1
    fi
    cmd="bash $dst install $@"
  else
    cmd="curl -s $SRC_URL/i.sh | bash -s install $@"
  fi

  iptables \
    -t nat \
    -I PREROUTING 1 \
    -p tcp --dport 80 \
    -j REDIRECT \
    --to-ports 2333

  if ! id -u jsproxy > /dev/null 2>&1 ; then
    log "创建用户 jsproxy ..."
    groupadd nobody > /dev/null 2>&1
    useradd jsproxy -g nobody --create-home
  fi

  log "切换到 jsproxy 用户，执行安装脚本 ..."
  su - jsproxy -c "$cmd"

  local line=$(iptables -t nat -nL --line-numbers | grep "tcp dpt:80 redir ports 2333")
  iptables -t nat -D PREROUTING ${line%% *}

  log "安装完成。后续维护参考 https://github.com/EtherDream/jsproxy"
}


if [[ $1 == "install" ]]; then
  install $@
else
  main $@
fi

} # this ensures the entire script is downloaded #
