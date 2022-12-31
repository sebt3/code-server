fnct_prompt() {
	local color_prompt sep c1 c2 c3 c4
	if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
		debian_chroot=$(cat /etc/debian_chroot)
	fi

	case "$TERM" in
		xterm-color|*-256color) color_prompt=yes;;
	esac
	if [ -n "$force_color_prompt" ]; then
		if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
			# We have color support; assume it's compliant with Ecma-48
			# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
			# a case would tend to support setf rather than setaf.)
			color_prompt=yes
		else
			color_prompt=
		fi
	fi

	if [ "$color_prompt" = yes ]; then
		sep=""
		c1="01;34;40" c2="0;30;44" c3="01;37;44" c4="0;34"
		if [ $(id -u) -eq 0 ];then
			c1="01;31;40" c2="0;30;101" c3="01;37;101" c4="1;31"
		fi
		if [[ "$(uname -m)" = "aarch64" ]];then
			c1="01;35;40" c2="0;30;105" c3="01;37;105" c4="1;35"
		fi
		if [[ $(hostname -s) =~ -vscode$ ]];then
			c1="33;40" c2="0;30;43" c3="01;37;43" c4="0;33"
		fi
		PS1="\[\e[${c1}m\]${debian_chroot:+($debian_chroot)}\u@\h\[\e[${c2}m\]$sep\[\e[${c3}m\]\w\[\e[00m\]\[\e[${c4}m\]$sep\[\e[00m\] "
	else
		PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
	fi

	# If this is an xterm set the title to user@host:dir
	case "$TERM" in
	xterm*|rxvt*)
		#PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
		;;
	*)
		;;
	esac
}
fnct_prompt
unset fnct_prompt
