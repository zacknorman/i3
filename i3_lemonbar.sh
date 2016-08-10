#!/bin/bash

## I3 bar with https://github.com/LemonBoy/bar
##
## Based on Electro7's work
## Modded by demure

. $(dirname $0)/i3_lemonbar_config

if [ $(pgrep -cx $(basename $0)) -gt 1 ] ; then
	printf "%s\n" "The status bar is already running." >&2
#	exit 1
fi

trap 'trap - TERM; kill 0' INT TERM QUIT EXIT

[ -e "${panel_fifo}" ] && rm "${panel_fifo}"
mkfifo "${panel_fifo}"

### EVENTS METERS

## Window title, "WIN"
xprop -spy -root _NET_ACTIVE_WINDOW | sed -un 's/.*\(0x.*\)/WIN\1/p' > "${panel_fifo}" &

## i3 Workspaces, "WSP"
## TODO : Restarting I3 breaks the IPC socket con. :(
$(dirname $0)/i3_workspaces.pl > "${panel_fifo}" &

# IRC, "IRC"
# only for init
#~/bin/irc_warn &

## Conky, "SYS"
conky -c $(dirname $0)/i3_lemonbar_conky > "${panel_fifo}" &

### UPDATE INTERVAL METERS
cnt_vol=${upd_vol}
cnt_bri=${upd_bri}
cnt_mail=${upd_mail}
cnt_mmpd=${upd_mmpd}
cnt_ext_ip=${upd_ext_ip}
cnt_gpg=${upd_gpg}
cnt_tmb=${upd_tmb}
cnt_temp=${upd_temp}
cnt_net=${upd_net}

while :; do

	## Volume, "VOL"
	if [ $((cnt_vol++)) -ge ${upd_vol} ]; then
		amixer get Master | awk -F'[]%[]' '/%/ {STATE=$5; VOL=$2} END {if (STATE == "off") {print "VOL×\n"} else {printf "VOL%d%%\n", VOL}}' > "${panel_fifo}" &
		cnt_vol=0
	fi

	## Brightness, "BRI"
	if [ $((cnt_bri++)) -ge ${upd_bri} ]; then
		## xbacklight doesn't work as this doesn't have xrandr access while running as the bar?
		printf "%s%s\n" "BRI" "$(paste /sys/class/backlight/*/{actual_brightness,max_brightness} | awk '{BRIGHT=$1/$2*100} END {printf "%.f", BRIGHT}')" > "${panel_fifo}"
		cnt_bri=0
	fi

	## Temperature Check, TMP
	if [ $((cnt_temp++)) -ge ${upd_temp} ]; then
		printf "%s%s\n" "TMP" "$(echo Ordinal LTX)" > "${panel_fifo}"
		cnt_temp=0
	fi

	## Network Check, NET
	if [ $((cnt_net++)) -ge ${upd_net} ]; then
		## Get IP and wifi strength
		printf "%s%s %s\n" "NET" "$(ip address show up scope global 2>/dev/null | awk '/inet/ {match($0, /\s+\w+\s(\w+\.\w+\.\w+\.\w+)\/\w+\s\w+\s\w+\.\w+\.\w+\.\w+\s\w+\s\w+\s(\w+)/, m)} END {if(m[1]!=""){print m[1] " " m[2]} else {print "none none"}}')" "$(iwconfig 2>/dev/null | awk '/Link/ {match($0, /\s+\w+\s\w+=([0-9]+)\/([0-9]+).*/, m)} END {if(m[1]!=""&&m[2]!=""){print int((m[1] / m[2]) * 100)} else {print "none"}}')" > "${panel_fifo}"
		cnt_net=0
	fi

	## Offlineimap, "EMA"
#	if [ $((cnt_mail++)) -ge ${upd_mail} ]; then
#		printf "%s%s\n" "EMA" "$(find $HOME/.mail/*/INBOX/new -type f 2>/dev/null | wc -l)" > "${panel_fifo}"
#		cnt_mail=0
#	fi

	## Multi Music Player Display
	if [ $((cnt_mmpd++)) -ge ${upd_mmpd} ]; then
		mmpd_check="$(grep -qxs 1 $HOME/.config/pianobar/isplaying && cat $HOME/.config/pianobar/nowplaying || echo 'none')"
		if [ "${mmpd_check}" != "none" ]; then
			printf "%s%s\n" "MMP" "${mmpd_check}" > "${panel_fifo}"
		  else
		## cmus
		mmpd_check="$(cmus-remote -Q 2>/dev/null | awk 'BEGIN {STATUS=0;STREAM=0;TITLE=0;ARTIST=0} {match($0, /^(status|stream|tag title|tag artist)\s(.*)/, m); if(m[1]=="status"){STATUS=m[2]};if(m[1]=="stream"){STREAM=m[2]}; if(m[1]=="tag title"){TITLE=m[2]}; if(m[1]=="tag artist"){ARTIST=m[2]}} END {if(STATUS!=0){if(STATUS=="playing"){if(STREAM!=0){print STREAM} else if(ARTIST!=0&&TITLE!=0){print ARTIST " - " TITLE} else if(TITLE!=0){print TITLE}else {print "cmus: no meta data"}} else if(STATUS=="paused"){print "cmus: paused"} else {print "none"}} else {print "none"}}')"
			if [ "${mmpd_check}" != "none" ]; then
				printf "%s%s\n" "MMP" "${mmpd_check}" > "${panel_fifo}"
			  else
				## mpd
				## Note this is my own mpd check (not elctro7's)
				## It will report if mpd is paused.
				mmpd_check="$(mpc status 2>/dev/null | awk 'BEGIN {STATUS=0;INFO=0} !/^volume/ {match($0, /^(\w+.*)/, p); match($0, /(\[playing\]|\[paused\])/, m); if(m[0]!=""){STATUS=m[1]}; if(p[0]!=""){INFO=p[0]}} END {if(STATUS!=0){if(STATUS=="[paused]"){print "mpd: paused"} else {print INFO}} else {print "none"}}')"
				if [ "${mmpd_check}" != "none" ]; then
					printf "%s%s\n" "MMP" "${mmpd_check}" > "${panel_fifo}"
				  else
					## mocp
					mmpd_check="$(mocp --info 2>/dev/null | awk 'BEGIN {STATE=0; TITLE=0; ARTIST=0} {match($0, /^(State|Title|Artist):\s(.*)/, m); if(m[1]=="State"){STATE=m[2]}; if(m[1]=="Artist"&&m[2]!=""){ARTIST=m[2]}; if(m[1]=="Title"&&m[2]!=""){TITLE=m[2]}} END {if(STATE!=0){if(STATE=="PLAY"){if(TITLE!=0){print TITLE} else {print "mocp: no meta data"}} else if(STATE=="PAUSE"){print "mocp: paused"} else {print "none"}} else {print "none"}}')"
					if [ "${mmpd_check}" != "none" ]; then
						printf "%s%s\n" "MMP" "${mmpd_check}" > "${panel_fifo}"
					  else
						## audacios
						mmpd_check="$(audtool --playback-status --current-song 2>/dev/null | awk 'BEGIN {STATUS=0; INFO=0} {if($0=="playing"||$0=="paused"){STATUS=$0}; if(STATUS=="playing"){INFO=$0}} END {if(INFO!=0){print INFO} else if(STATUS=="paused"){print "audacios: paused"} else {print "none"}}')"
						if [ "${mmpd_check}" != "none" ]; then
							printf "%s%s\n" "MMP" "${mmpd_check}" > "${panel_fifo}"
						  else
							## This makes scaling easier
							printf "%s%s\n" "MMP" "none" > "${panel_fifo}"
						fi
					fi
				fi
			fi
		fi
	cnt_mmpd=0
	fi

	## Thinkpad Milti Battery, "TMB"
	## Works for normal batteries now too.
	if [ $((cnt_tmb++)) -ge ${upd_tmb} ]; then
		## Check for BAT0
		if [ -e /sys/class/power_supply/sbs-5-000b/uevent ]; then
			BAT0="/sys/class/power_supply/sbs-5-000b/uevent"
		fi

		## Check for BAT1
		if [ -e /sys/class/power_supply/BAT1/uevent ]; then
			BAT1="/sys/class/power_supply/BAT1/uevent"
		fi

		if [ "${BAT0}" != "" ] || [ "${BAT1}" != "" ]; then
			## Originally "/sys/class/power_supply/BAT{0..1}/uevent" but changed into variables make work for non thinkpad cases. paste fails if it can't find a passed file.
			printf "%s%s %s\n" "TMB" "$(paste -d = ${BAT0} ${BAT1} 2>/dev/null | awk '/ENERGY_FULL=/||/ENERGY_NOW=/||/STATUS/||/CHARGE_NOW/||/CHARGE_FULL/ {split($0,a,"="); if(a[2]~/Discharging/||a[4]~/Discharging/){CHARGE="D"} else if(a[2]~/Charging/||a[4]~/Charging/){CHARGE="C"} else if (a[2]~/Full/||a[4]~/Full/){CHARGE="F"}; if(a[1]~/FULL/){FULL=a[2]+a[4]}; if(a[1]~/NOW/){NOW=a[2]+a[4]};} END {if(NOW!=""){PERC=int((NOW/FULL)*100)} else {PERC="none"}; printf("%s %s\n", PERC, CHARGE)}')" "$(acpi -b | awk '/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ {if($5!=""){print $5}}')" > "${panel_fifo}" 
			else
			printf "%s%s\n" "TMB" "none" > "${panel_fifo}"
		fi
		cnt_tmb=0
	fi

	## GPG Check, "GPG"
	if [ $((cnt_gpg++)) -ge ${upd_gpg} ]; then
		export DISPLAY=''
		printf "Ordinal LT vX Online"
#		printf "%s%s\n" "GPG" "$(gpg-connect-agent 'keyinfo --list' /bye 2>/dev/null | awk 'BEGIN{CACHED=0} /^S/ {match($0, /S\sKEYINFO\s\S+\s\S\s\S+\s\S+\s(\S)\s\S\s\S+\s\S+\s\S/, m); if(m[1]==1){CACHED=1}} END{if($0!=""){print CACHED} else {print "none"}}')" > "${panel_fifo}"
		cnt_gpg=0
	fi

	## External IP, "EXT"
	if [ $((cnt_ext_ip++)) -ge ${upd_ext_ip} ]; then
		printf "%s%s\n" "EXT" "$(wget --no-proxy http://checkip.dyndns.org/ -q -O - | grep -Eo '\<[[:digit:]]{1,3}(\.[[:digit:]]{1,3}){3}\>' || echo 'err')" > "${panel_fifo}"
		cnt_ext_ip=0
	fi

	## Finally, wait 1 second
	sleep 1s;

done &

#### LOOP FIFO

cat "${panel_fifo}" | $(dirname $0)/i3_lemonbar_parser.sh \
	| lemonbar -p -f "${font}" -f "${iconfont}" -g "${geometry}" -B "${color_back}" -F "${color_fore}" &

wait

