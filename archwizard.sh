#!/usr/bin/env bash

# Apropos - A simple, post-arch, bash installer script for my configuration
# files and system setup.
# Chris Iñigo <https://github.com/x1nigo>

### GENERAL VARIABLES ###

dotfilesrepo="https://github.com/x1nigo/dotfiles.git"
export TERM=ansi

### FUNCTIONS ###

installpkg() {
	pacman --noconfirm --needed -S "$1" >/dev/null 2>&1
}

error() {
	printf "%s\n" "$1" >&2
	exit 1
}

welcomemsg() {
	whiptail --title "Welcome\!" \
		--msgbox "This script should be able to install my configuration files for Arch Linux.\\n-CB2\\n\\nWARNING: This should be run as root - preferrably on a fresh install of Arch." 12 60
}

getuserandpass() {
	clear
	echo "Please enter a username (only lowercase letters)."
	printf "Username: "
	read -r name
	echo "Next, your password for this account."
	printf "Password: "
	read -r pass1
	echo "Retype your password."
	printf "Password: "
	read -r pass2
 	[ "$pass1" = "$pass2" ] || error "Passwords do not match."
}

adduserandpass() {
	useradd -m -g wheel "$name"
	echo "$name:$pass1" | chpasswd
	unset pass1 pass2
	srcdir="/home/$name/.local/src"
	echo "%wheel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/temp
	sudo -u "$name" mkdir -p "$srcdir"
}

maininstall() {
	clear
	echo "Installing \`$1\` ($n of $total). $2."
	installpkg "$1"
}

installationloop() {
	total=$(wc -l < progs.csv)
	while IFS=, read -r program comment; do
		n=$((n + 1))
		maininstall "$program" "$comment"
	done < progs.csv
}

installconfig() {
	clear
	echo "Installing configuration files..."
	sudo -u "$name" git -C "$srcdir" clone "$dotfilesrepo" >/dev/null 2>&1
	# Install dwm and other suckless software.
 	clear
  	echo "Compiling suckless software..."
	for i in dwm st dmenu dwmblocks; do
		sudo -u "$name" git -C "$srcdir" clone "https://github.com/x1nigo/$i.git" >/dev/null 2>&1
		cd "$srcdir"/"$i" && make clean install >/dev/null 2>&1
	done
	# Transfer ".local" and ".config" files to their respective locations.
 	clear
 	echo "Adjusting miscellaneous settings..."
	cd "$srcdir"
	sudo -u "$name" cp -rfT dotfiles /home/$name/
	chmod -R +x /home/$name/.local/bin
 	# Install the lf file manager.
 	clear "Configuring the \`lf\` file manager..."
  	cd /home/$name/.config/lf && make install
	# Enable tap to click and natural scrolling.
	[ ! -f /etc/X11/xorg.conf.d/40-libinput.conf ] && printf 'Section "InputClass"
		Identifier "libinput touchpad catchall"
		MatchIsTouchpad "on"
		MatchDevicePath "/dev/input/event*"
		Driver "libinput"
	# Enable left mouse button by tapping
	Option "Tapping" "on"
	Option "NaturalScrolling" "on"
EndSection' >/etc/X11/xorg.conf.d/40-libinput.conf
	# Make pacman look good.
	grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
}

resetpermissions() {
	clear
 	echo "Changing permissions for the user..."
	rm -f /etc/sudoers.d/temp
	echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/00-wheel-sudo
 	usermod -a -G video "$name"
	chsh -s /bin/zsh "$name"
}

exitmsg() {
	whiptail --title "Installation Complete\!" \
		--msgbox "Congratulations! You now have a fully functioning Arch Linux desktop which you may now use as your daily driver.\\n\\nProvided that there were no hidden errors, you're good to go! And if there were, I'm sure you can figure it out.\\n\\n-CB2" 13 80
}

### EXECUTION PHASE ###

pacman --noconfirm --needed -Sy libnewt || error "Make sure you're running this Arch-based distribution as root with an internet connection."
welcomemsg || error "User exited."
getuserandpass # Already has a custom error message.
adduserandpass || error "User exited."
installationloop || error "User exited."
installconfig || error "User exited."
resetpermissions || error "User exited."
exitmsg
