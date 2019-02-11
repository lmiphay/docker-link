#!/sbin/openrc-run
# Copyright 1999-2019 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

container=${RC_SVCNAME#*.}

description=""
logfile="/var/log/docker-link.log"

dl_log()
{
    echo "$(date '+%Y%m%d:%H:%M:%S'): $@" >>$logfile
}

wait_up()
{
    local count=0

    until [ "$(docker inspect -f {{.State.Running}} $container)" == "true" ] ; do
	sleep 1.0;
	let count+=1
	if [ $count -eq "${STARTUP_WAIT:-20}" ] ; then
	    dl_log "Failed to start container $container"
	    return 1
	fi
    done

    dl_log "Container $container started in $count seconds"

    return 0
}

depend() {
    need net docker
    after "container.${container}"
    config "/etc/conf.d/${RC_SVCNAME}"
}

start() {
    if wait_up ; then
	ebegin "Add public IP to container $container"
	/usr/bin/docker-link start "$container" "${IP_ADDRESS}" "${BRIDGE}"
	eend $?
    fi
}

stop() {
    ebegin "Removing public IP from container $container"
    /usr/bin/docker-link stop "$container"
    eend $?
}
