#!/bin/bash

# Fightcade 2 Linux Installation Script
# Author: blueminder

# Includes:
# * Joystick/Keyboard Navigation (https://github.com/blueminder/fightcade-joystick-kb-controls)
# * Flycast Dojo git snapshot Arch Linux Package (https://github.com/blueminder/aur-flycast-dojo-git/releases)
# * Script to switch between bundled & system Flycast Dojo versions

# Tested on:
# * EndeavourOS 03-2023 (Arch Linux)
# * Ubuntu 22.04

SDIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

TMPDIR=/tmp/fci-`date +%s`
mkdir $TMPDIR
echo $TMPDIR > ${SDIR}/TMPDIR

cd ${SDIR}

PAYLOAD_LINE=`awk '/^__PAYLOAD_BELOW__/ {print NR + 1; exit 0; }' $0`

tail -n+$PAYLOAD_LINE $0 > "${TMPDIR}/payload.tgz"
tar zxf "${TMPDIR}/payload.tgz" -C ${TMPDIR}

chmod +x "${TMPDIR}/yad"

INSTALLER_PID=$$

export LOG="${TMPDIR}/install.log"
touch $LOG

PCTFILE="${TMPDIR}/percent"
touch $PCTFILE

STEPFILE="${TMPDIR}/step"
touch $STEPFILE

sudo echo "Authenticated."

# ubuntu: install dependencies for yad support if not present
if type apt &> /dev/null; then	
	if [ $(sudo dpkg-query -W -f='${Status}' libgtksourceview-3.0-1 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
		sudo apt-get -y install libgtksourceview-3.0-1;
	fi

	if [ $(sudo dpkg-query -W -f='${Status}' libgspell-1-2 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
		sudo apt-get -y install libgspell-1-2;
	fi
fi

CURRENTSTEP=1

function open_about() {
	SDIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
	TMPDIR=$(cat ${SDIR}/TMPDIR)
	exec "${TMPDIR}/yad"\
	--about\
	--pname="Fightcade+ Linux Installer"\
	--image="${TMPDIR}/fcp.png"\
	--comments="A graphical Linux installer for Fightcade and additional QoL enhancements."\
	--authors="blueminder (Enrique Santos)"\
	--pversion=20230618\
	--license=GPL3
}
export -f open_about

function open_active_log() {
	SDIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
	TMPDIR=$(cat "${SDIR}/TMPDIR")
	(tail -f "$LOG" | exec "${TMPDIR}/yad" --text-info --tail --listen --title="Install Log" --window-icon="download" --height=400 --width=800 --button="yad-close") &
}
export -f open_active_log

function open_log() {
	SDIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
	(cat "$LOG" | exec "${SDIR}/yad" --text-info --tail --title="Install Log" --window-icon="download" --height=400 --width=800 --button="yad-close") &
}
export -f open_log

function kill_proc() {
	kill $1
	kill -USR1 $YAD_PID
}
export -f kill_proc


echo -e 'true
Fightcade
Installs Fightcade &amp; all its dependencies. Placed in ~/.fightcade2 directory.
true
Joystick &amp; Keyboard Controls
Adds Joystick &amp; Numpad controls to the Fightcade frontend. Ideal for arcade cabinets and lazy gamers.
true
Flycast Dojo (latest prerelease)
Downloads &amp; installs the latest Flycast Dojo prerelease. Includes script to switch between Flycast Dojo versions used by Fightcade.' > "${TMPDIR}/install_options.list"

echo -e 'false
Street Fighter III: 3rd Strike (Grouflon)
FBNeo Lua Training Scripts
false
Virtua Fighter 4: Final Tuned (Nailok)
Flycast Lua Training Scripts' > "${TMPDIR}/lua_options.list"

PLUG=`date +%s`

INSTALL_JOY=false
INSTALL_DOJO=false
INSTALL_3S_LUA=false
INSTALL_VF4FT_LUA=false

res1=$(mktemp /tmp/iface1.XXXXXXXX)
res2=$(mktemp /tmp/iface2.XXXXXXXX)

"${TMPDIR}/yad"\
 --plug=$PLUG\
 --tabnum=1\
 --list --checklist\
 --column=Select\
 --column=Component\
 --column=Description < "${TMPDIR}/install_options.list"\
 --tooltip-column=3\
 --hide-column=3 &> $res1 &

"${TMPDIR}/yad"\
 --plug=$PLUG\
 --tabnum=2\
 --list --checklist\
 --column=Select\
 --column=Component\
 --column=Description < "${TMPDIR}/lua_options.list"\
 --tooltip-column=3\
 --hide-column=3 &> $res2 &

action=$("${TMPDIR}/yad"\
 --notebook\
 --tab-pos=bottom\
 --key=$PLUG\
 --tab="Main Components"\
 --tab="Lua Scripts"\
 --window-icon="input-gaming"\
 --title="Install Fightcade"\
 --text="Fightcade+ Linux Installer"\
 --width=450\
 --height=300\
 --image="${TMPDIR}/fcp.png"\
 --text-align=center\
 --button=yad-about:"bash -c open_about"\
 --button=yad-cancel\
 --button=yad-ok)
RET=$?

TAB1=$(< $res1)
TAB2=$(< $res2)

TOTALSTEPS=6

case "$TAB1" in
	*"TRUE|Joystick &amp; Keyboard Controls"*)
	INSTALL_JOY=true
	TOTALSTEPS=$(($TOTALSTEPS+1))
	;;
esac

case "$TAB1" in
	*"TRUE|Flycast Dojo (latest prerelease)"*)
	INSTALL_DOJO=true
	TOTALSTEPS=$(($TOTALSTEPS+1))
	;;
esac

case "$TAB2" in
	*"TRUE|Street Fighter III"*)
	INSTALL_3S_LUA=true
	TOTALSTEPS=$(($TOTALSTEPS+1))
	;;
esac

case "$TAB2" in
	*"TRUE|Virtua Fighter 4"*)
	INSTALL_VF4FT_LUA=true
	TOTALSTEPS=$(($TOTALSTEPS+1))
	;;
esac

if [ $RET -lt 2 ]; then
	exit 0
fi

echo 0 > $PCTFILE

(CURRENT_PID=$$
LASTECHO=""
while true
	do
		OUT="1:#$(cat $STEPFILE)"
		if [ "$OUT" != "$LASTECHO" ]; then
			echo $OUT
			LASTECHO=$OUT
		fi
		echo "1:$(cat $PCTFILE)"
	done | "${TMPDIR}/yad" --progress --pulsate --enable-log --log-on-top --log-expanded --log-height=200 --auto-close --auto-kill --title="Installation Progress" --window-icon="${TMPDIR}/fcp.png" --bar="":NORM --width=450 --button="Show Log!gtk-info:bash -c open_active_log" --button="Cancel!gtk-cancel:bash -c 'kill_proc $INSTALLER_PID'") &

cd $TMPDIR

{
echo "Installing Dependencies..." | tee $STEPFILE
echo 5 > $PCTFILE

# check if arch-based distro
if type pacman &> /dev/null; then
	if ! yay_loc="$(type -p yay)" || [[ -z $yay_loc ]]; then
		git clone https://aur.archlinux.org/yay.git
		chown -R "$USER:" yay/
		cd yay
		makepkg -si --noconfirm
	fi
	
	yay -S --noconfirm rsync wine wine-mono lib32-mpg123 lib32-libxss lib32-libcurl-gnutls libcurl-gnutls libzip miniupnpc lua53 libao lib32-faudio
	
	# install libdxvk
	wget "https://github.com/eclairevoyant.gpg"
	sudo pacman-key --add eclairevoyant.gpg
	yay -S --noconfirm lib32-sdl2 lib32-vulkan-icd-loader libdxvk
	rm eclairevoyant.gpg
elif type apt &> /dev/null; then
	sudo dpkg --add-architecture i386
	sudo mkdir -pm755 /etc/apt/keyrings
	sudo wget -O "/etc/apt/keyrings/winehq-archive.key" "https://dl.winehq.org/wine-builds/winehq.key"

	RELEASE=$(lsb_release -cs)
	sudo wget -NP /etc/apt/sources.list.d/ "https://dl.winehq.org/wine-builds/ubuntu/dists/${RELEASE}/winehq-${RELEASE}.sources"

	sudo apt-get update
	sudo apt-get -y install --install-recommends winehq-staging
	sudo apt-get -y install libcurl3-gnutls libzip4 libminiupnpc17 liblua5.3-0 libao4 dxvk
fi

CURRENTSTEP=$(($CURRENTSTEP+1))
echo $(((100 * $CURRENTSTEP)/$TOTALSTEPS)) > $PCTFILE
echo "Downloading Fightcade..." | tee step
wget "https://web.fightcade.com/download/Fightcade-linux-latest.tar.gz"
tar zxvf Fightcade-linux-latest.tar.gz

CURRENTSTEP=$(($CURRENTSTEP+1))
echo $(((100 * $CURRENTSTEP)/$TOTALSTEPS)) > $PCTFILE
echo "Installing Fightcade..." | tee $STEPFILE
FC_DIR="$HOME/.fightcade2"
mv Fightcade "$FC_DIR"
rm Fightcade-linux-latest.tar.gz

# set fbneo audio default to xaudio2
cd $FC_DIR
sed -i "40ised -i \'s/nAudSelect 0/nAudSelect 1/\' ./emulator/fbneo/config/fcadefbneo.ini" Fightcade2.sh

# create symbolic links for included flycast dojo binary
sudo ln -s "/usr/lib/libzip.so" "/usr/lib/libzip.so.4"
sudo ln -s "/usr/lib/liblua5.3.so" "/usr/lib/liblua5.3.so.0"

# gamepad/joystick controls
if [[ "$INSTALL_JOY" == "true" ]]; then
	cd "$FC_DIR/fc2-electron/resources/app/inject/"
	CURRENTSTEP=$(($CURRENTSTEP+1))
	echo $(((100 * $CURRENTSTEP)/$TOTALSTEPS)) > $PCTFILE
	echo "Installing Joystick &amp; Keyboard Controls..." | tee $STEPFILE
	wget "https://raw.githubusercontent.com/blueminder/fightcade-joystick-kb-controls/main/inject.js"
fi

cd $TMPDIR

if [[ "$INSTALL_DOJO" == "true" ]]; then
	CURRENTSTEP=$(($CURRENTSTEP+1))
	echo $(((100 * $CURRENTSTEP)/$TOTALSTEPS)) > $PCTFILE
	echo "Downloading Latest Flycast Dojo Prerelease..." | tee $STEPFILE

	if type pacman &> /dev/null; then
		yay -S --noconfirm zlib alsa-lib libpulse lua
	fi

	wget -O "${TMPDIR}/linux-flycast-dojo-0.5.33.zip" "https://github.com/blueminder/flycast-dojo/releases/download/dojo-0.5.33/linux-flycast-dojo-0.5.33.zip"
	unzip "${TMPDIR}/linux-flycast-dojo-0.5.33.zip" -d "$FC_DIR/emulator/flycast/"
	chmod +x "$FC_DIR/emulator/flycast/flycast-dojo-x86_64.AppImage"

	cd "$FC_DIR/emulator/flycast"
	cp "${TMPDIR}/switch_flycast_version.sh" "$FC_DIR/emulator/flycast/switch_flycast_version.sh"
	chmod +x switch_flycast_version.sh
	
	cd "$HOME/.local/share/applications"
	cp "${TMPDIR}/SwitchFlycast.desktop" "$HOME/.local/share/applications/SwitchFlycast.desktop"

	if [ -d "$HOME/.local/share/flycast-dojo" ]; then
		rm -rf "$HOME/.local/share/flycast-dojo"
	fi
	
	if [ -d "$HOME/.config/flycast-dojo" ]; then
		rm -rf "$HOME/.config/flycast-dojo"
	fi

	ln -s "$HOME/.fightcade2/emulator/flycast" "$HOME/.local/share/flycast-dojo"
	ln -s "$HOME/.fightcade2/emulator/flycast" "$HOME/.config/flycast-dojo"
fi

CURRENTSTEP=$(($CURRENTSTEP+1))
echo $(((100 * $CURRENTSTEP)/$TOTALSTEPS)) > $PCTFILE
echo "Initializing ROM Directories..." | tee $STEPFILE	

# initialize emulator rom dirs
mkdir -p "$HOME/.fightcade2/emulator/flycast/ROMs"
mkdir -p "$HOME/.fightcade2/emulator/fbneo/ROMs"
mkdir -p "$HOME/.fightcade2/emulator/ggpofba/ROMs"
mkdir -p "$HOME/.fightcade2/emulator/snes9x/ROMs"

FBNEO_LUA_DIR="$HOME/.fightcade2/emulator/fbneo/lua"

if $INSTALL_3S_LUA; then
	CURRENTSTEP=$(($CURRENTSTEP+1))
	echo $(((100 * $CURRENTSTEP)/$TOTALSTEPS)) > $PCTFILE
	echo "Installing Street Fighter III: 3rd Strike Lua Scripts by Grouflon..." | tee $STEPFILE
	mkdir -p $FBNEO_LUA_DIR
	cd $FBNEO_LUA_DIR
	wget -O "${FBNEO_LUA_DIR}/3rd_training_lua.zip" "https://github.com/Grouflon/3rd_training_lua/archive/refs/heads/master.zip"
	unzip "${FBNEO_LUA_DIR}/3rd_training_lua.zip"
	rm "${FBNEO_LUA_DIR}/3rd_training_lua.zip"
fi

FLYCAST_LUA_DIR="$HOME/.fightcade2/emulator/flycast/lua"

if "$INSTALL_VF4FT_LUA"; then
	CURRENTSTEP=$(($CURRENTSTEP+1))
	echo $(((100 * $CURRENTSTEP)/$TOTALSTEPS)) > $PCTFILE
	echo "Installing Virtua Fighter 4: Final Tuned Lua Scripts by Nailok..." | tee $STEPFILE
	mkdir -p $FLYCAST_LUA_DIR
	cd $FLYCAST_LUA_DIR
	wget -O "${FLYCAST_LUA_DIR}/VF4-Training.zip" "https://github.com/Nailok/VF4-Training/archive/refs/heads/master.zip"
	unzip "${FLYCAST_LUA_DIR}/VF4-Training.zip"
	rm "${FLYCAST_LUA_DIR}/VF4-Training.zip"
fi

# set default desktop icons & associations
sed -i "\$s/^/#/" "$HOME/.fightcade2/Fightcade2.sh"
chmod +x "$HOME/.fightcade2/Fightcade2.sh"
"$HOME/.fightcade2/Fightcade2.sh"
sed -i "\$s/#//" "$HOME/.fightcade2/Fightcade2.sh"

cd $TMPDIR

FILENAME=""
if [ "$1" ]; then
	wget "$1"
	FILENAME=$(basename "$1")
	chown -R "$USER:" "$FILENAME"
fi

if [ "$2" ]; then
	unzip "$FILENAME" -d "$FC_DIR/$2"
	rm "$FILENAME"
fi

echo 100 > $PCTFILE
echo "Installation Complete." | tee $STEPFILE
} &> $LOG

exec "${TMPDIR}/yad"\
 --title="Installation Complete"\
 --button="Launch Fightcade!gtk-ok:bash $HOME/.fightcade2/Fightcade2.sh"\
 --button="Show Log!gtk-info:bash -c open_log"\
 --button=yad-close\
 --window-icon="package-install"

export -n LOG

rm "${SDIR}/TMPDIR"

exit 0

__PAYLOAD_BELOW__
