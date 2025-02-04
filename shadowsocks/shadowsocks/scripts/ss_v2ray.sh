#!/bin/sh

eval `dbus export ss`
source /jffs/softcenter/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
V2RAY_CONFIG_FILE="/jffs/softcenter/ss/v2ray.json"
url_main="https://raw.githubusercontent.com/paldier/softcenterarm/master/v2ray_binary"
url_back=""

get_latest_version(){
	rm -rf /tmp/v2ray_latest_info.txt
	echo_date "检测V2Ray最新版本..."
	curl --connect-timeout 8 -s $url_main/latest.txt > /tmp/v2ray_latest_info.txt
	if [ "$?" == "0" ];then
		if [ -z "`cat /tmp/v2ray_latest_info.txt`" ];then
			echo_date "获取V2Ray最新版本信息失败！使用备用服务器检测！"
			get_latest_version_backup
		fi
		if [ -n "`cat /tmp/v2ray_latest_info.txt|grep "404"`" ];then
			echo_date "获取V2Ray最新版本信息失败！使用备用服务器检测！"
			get_latest_version_backup
		fi
		V2VERSION=`cat /tmp/v2ray_latest_info.txt | sed 's/v//g'` || 0
		echo_date "检测到V2Ray最新版本：v$V2VERSION"
		if [ ! -f "/jffs/softcenter/bin/v2ray" -o ! -f "/jffs/softcenter/bin/v2ctl" ];then
			echo_date "v2ray安装文件丢失！重新下载！"
			CUR_VER="0"
		else
			CUR_VER=`v2ray -version 2>/dev/null | head -n 1 | cut -d " " -f2 | sed 's/v//g'` || 0
			echo_date "当前已安装V2Ray版本：v$CUR_VER"
		fi
		COMP=`versioncmp $CUR_VER $V2VERSION`
		if [ "$COMP" == "1" ];then
			[ "$CUR_VER" != "0" ] && echo_date "V2Ray已安装版本号低于最新版本，开始更新程序..."
			update_now v$V2VERSION
		else
			V2RAY_LOCAL_VER=`/jffs/softcenter/bin/v2ray -version 2>/dev/null | head -n 1 | cut -d " " -f2`
			V2RAY_LOCAL_DATE=`/jffs/softcenter/bin/v2ray -version 2>/dev/null | head -n 1 | cut -d " " -f4`
			[ -n "$V2RAY_LOCAL_VER" ] && dbus set ss_basic_v2ray_version="$V2RAY_LOCAL_VER"
			[ -n "$V2RAY_LOCAL_DATE" ] && dbus set ss_basic_v2ray_date="$V2RAY_LOCAL_DATE"
			echo_date "V2Ray已安装版本已经是最新，退出更新程序!"
		fi
	else
		echo_date "获取V2Ray最新版本信息失败！使用备用服务器检测！"
		get_latest_version_backup
	fi
}

get_latest_version_backup(){
	echo_date "目前还没有任何备用服务器！"
	echo_date "获取V2Ray最新版本信息失败！请检查到你的网络！"
	echo_date "==================================================================="
	echo XU6J03M6
	exit 1
}

# get_latest_version_backup(){
# 	rm -rf /tmp/v2ray_latest_info.txt
# 	echo_date "检测V2Ray最新版本..."
# 	curl --connect-timeout 8 -s $url_back/latest.txt > /tmp/v2ray_latest_info.txt
# 	if [ "$?" == "0" ];then
# 		if [ -z "`cat /tmp/v2ray_latest_info.txt`" ];then
# 			echo_date "获取V2Ray最新版本信息失败！退出！"
# 			echo_date "==================================================================="
# 			echo XU6J03M6
# 			exit 1
# 		fi
# 		if [ -n "`cat /tmp/v2ray_latest_info.txt|grep "404"`" ];then
# 			echo_date "获取V2Ray最新版本信息失败！退出！"
# 			echo_date "==================================================================="
# 			echo XU6J03M6
# 			exit 1
# 		fi
# 		V2VERSION=`cat /tmp/v2ray_latest_info.txt | sed 's/v//g'`
# 		echo_date "检测到V2Ray最新版本：v$V2VERSION"
# 		if [ ! -f "/jffs/softcenter/bin/v2ray" -o ! -f "/jffs/softcenter/bin/v2ctl" ];then
# 			echo_date "v2ray安装文件丢失！重新下载！"
# 			CUR_VER="0"
# 		else
# 			CUR_VER=`v2ray -version 2>/dev/null | head -n 1 | cut -d " " -f2 | sed 's/v//g'` || 0
# 			echo_date "当前已安装V2Ray版本：v$CUR_VER"
# 		fi
# 		COMP=`versioncmp $V2VERSION $CUR_VER`
# 		if [ "$COMP" == "1" ];then
# 			[ "$CUR_VER" != "0" ] && echo_date "V2Ray已安装版本号低于最新版本，开始更新程序..."
# 			update_now_backup v$V2VERSION
# 		else
# 			V2RAY_LOCAL_VER=`/jffs/softcenter/bin/v2ray -version 2>/dev/null | head -n 1 | cut -d " " -f2`
# 			V2RAY_LOCAL_DATE=`/jffs/softcenter/bin/v2ray -version 2>/dev/null | head -n 1 | cut -d " " -f5`
# 			[ -n "$V2RAY_LOCAL_VER" ] && dbus set ss_basic_v2ray_version="$V2RAY_LOCAL_VER"
# 			[ -n "$V2RAY_LOCAL_DATE" ] && dbus set ss_basic_v2ray_date="$V2RAY_LOCAL_DATE"
# 			echo_date "V2Ray已安装版本已经是最新，退出更新程序!"
# 		fi
# 	else
# 		echo_date "获取V2Ray最新版本信息失败！请检查到你的网络！"
# 		echo_date "==================================================================="
# 		echo XU6J03M6
# 		exit 1
# 	fi
# }

update_now(){
	rm -rf /tmp/v2ray
	mkdir -p /tmp/v2ray && cd /tmp/v2ray

	echo_date "开始下载校验文件：md5sum.txt"
	wget --no-check-certificate --timeout=20 -qO - $url_main/$1/md5sum.txt > /tmp/v2ray/md5sum.txt
	if [ "$?" != "0" ];then
		echo_date "md5sum.txt下载失败！"
		md5sum_ok=0
	else
		md5sum_ok=1
		echo_date "md5sum.txt下载成功..."
	fi
	
	echo_date "开始下载v2ray程序"
	wget --no-check-certificate --timeout=20 --tries=1 $url_main/$1/v2ray
	#curl -L -H "Cache-Control: no-cache" -o /tmp/v2ray/v2ray $url_main/$1/v2ray
	if [ "$?" != "0" ];then
		echo_date "v2ray下载失败！"
		v2ray_ok=0
	else
		v2ray_ok=1
		echo_date "v2ray程序下载成功..."
	fi

	echo_date "开始下载v2ctl程序"
	wget --no-check-certificate --timeout=20 --tries=1 $url_main/$1/v2ctl
	if [ "$?" != "0" ];then
		echo_date "v2ctl下载失败！"
		v2ctl_ok=0
	else
		v2ctl_ok=1
		echo_date "v2ctl程序下载成功..."
	fi

	if [ "$md5sum_ok=1" ] && [ "$v2ray_ok=1" ] && [ "$v2ctl_ok=1" ];then
		check_md5sum
	else
		echo_date "使用备用服务器下载..."
		update_now_backup $1
	fi
}

update_now_backup(){
	echo_date "下载失败，请检查你的网络！"
	echo_date "==================================================================="
	echo XU6J03M6
	exit 1
}

# update_now_backup(){
# 	rm -rf /tmp/v2ray
# 	mkdir -p /tmp/v2ray && cd /tmp/v2ray
# 
# 	echo_date "开始下载校验文件：md5sum.txt"
# 	wget --no-check-certificate --timeout=20 -qO - $url_back/$1/md5sum.txt > /tmp/v2ray/md5sum.txt
# 	if [ "$?" != "0" ];then
# 		echo_date "md5sum.txt下载失败！"
# 		md5sum_ok=0
# 	else
# 		md5sum_ok=1
# 		echo_date "md5sum.txt下载成功..."
# 	fi
# 	
# 	echo_date "开始下载v2ray程序"
# 	wget --no-check-certificate --timeout=20 --tries=1 $url_back/$1/v2ray
# 	if [ "$?" != "0" ];then
# 		echo_date "v2ray下载失败！"
# 		v2ray_ok=0
# 	else
# 		v2ray_ok=1
# 		echo_date "v2ray程序下载成功..."
# 	fi
# 
# 	echo_date "开始下载v2ctl程序"
# 	wget --no-check-certificate --timeout=20 --tries=1 $url_back/$1/v2ctl
# 	if [ "$?" != "0" ];then
# 		echo_date "v2ctl下载失败！"
# 		v2ctl_ok=0
# 	else
# 		v2ctl_ok=1
# 		echo_date "v2ctl程序下载成功..."
# 	fi
# 
# 	if [ "$md5sum_ok=1" ] && [ "$v2ray_ok=1" ] && [ "$v2ctl_ok=1" ];then
# 		check_md5sum
# 	else
# 		echo_date "下载失败，请检查你的网络！"
# 		echo_date "==================================================================="
# 		echo XU6J03M6
# 		exit 1
# 	fi
# }

check_md5sum(){
	cd /tmp/v2ray
	echo_date "校验下载的文件!"
	V2RAY_LOCAL_MD5=`md5sum v2ray|awk '{print $1}'`
	V2RAY_ONLINE_MD5=`cat md5sum.txt|grep -w v2ray|awk '{print $1}'`
	V2CTL_LOCAL_MD5=`md5sum v2ctl|awk '{print $1}'`
	V2CTL_ONLINE_MD5=`cat md5sum.txt|grep v2ctl|awk '{print $1}'`
	if [ "$V2RAY_LOCAL_MD5"x = "$V2RAY_ONLINE_MD5"x ] && [ "$V2CTL_LOCAL_MD5"x = "$V2CTL_ONLINE_MD5"x ];then
		echo_date "文件校验通过!"
		install_binary
	else
		echo_date "校验未通过，可能是下载过程出现了什么问题，请检查你的网络！"
		echo_date "==================================================================="
		echo XU6J03M6
		exit 1
	fi
}

install_binary(){
	echo_date "开始覆盖最新二进制!"
	if [ "`pidof v2ray`" ];then
		echo_date "为了保证更新正确，先关闭v2ray主进程... "
		killall v2ray >/dev/null 2>&1
		move_binary
		sleep 1
		start_v2ray
	else
		move_binary
	fi
}

move_binary(){
	echo_date "开始替换v2ray二进制文件... "
	mv /tmp/v2ray/v2ray /jffs/softcenter/bin/v2ray
	mv /tmp/v2ray/v2ctl /jffs/softcenter/bin/v2ctl
	chmod +x /jffs/softcenter/bin/v2*
	V2RAY_LOCAL_VER=`/jffs/softcenter/bin/v2ray -version 2>/dev/null | head -n 1 | cut -d " " -f2`
	V2RAY_LOCAL_DATE=`/jffs/softcenter/bin/v2ray -version 2>/dev/null | head -n 1 | cut -d " " -f5`
	[ -n "$V2RAY_LOCAL_VER" ] && dbus set ss_basic_v2ray_version="$V2RAY_LOCAL_VER"
	[ -n "$V2RAY_LOCAL_DATE" ] && dbus set ss_basic_v2ray_date="$V2RAY_LOCAL_DATE"
	echo_date "v2ray二进制文件替换成功... "
}

close_in_five(){
	echo_date "插件将在5秒后自动关闭！！"
	local i=5
	while [ $i -ge 0 ]
	do
		sleep 1
		echo_date $i
		let i--
	done
	dbus set ss_basic_enable="0"
	disable_ss >/dev/null
	echo_date "插件已关闭！！"
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	unset_lock
	exit
}

start_v2ray(){
	echo_date "开启v2ray进程... "
	cd /jffs/softcenter/bin
	#export GOGC=30
	v2ray --config=/jffs/softcenter/ss/v2ray.json >/dev/null 2>&1 &
	local V2PID
	local i=10
	until [ -n "$V2PID" ]
	do
		i=$(($i-1))
		V2PID=`pidof v2ray`
		if [ "$i" -lt 1 ];then
			echo_date "v2ray进程启动失败！"
			close_in_five
		fi
		sleep 1
	done
	echo_date v2ray启动成功，pid：$V2PID
}

echo_date "==================================================================="
echo_date "                v2ray程序更新(Shell by sadog)"
echo_date "==================================================================="
get_latest_version
echo_date "==================================================================="
