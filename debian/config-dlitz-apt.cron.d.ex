#
# Regular cron jobs for the config-dlitz-apt package.
#
0 4	* * *	root	[ -x /usr/bin/config-dlitz-apt_maintenance ] && /usr/bin/config-dlitz-apt_maintenance
