#!/bin/bash
#
# Init file for supervisord-fastchat
#
# chkconfig: 2345 55 25
# description: supervisor server daemon
#
# processname: supervisord-fastchat
#

NAME="supervisord-fastchat"
CONFIG=/etc/supervisord.ini
if [ ! -f ${CONFIG} ]; then
    CONFIG=/data/llm/FastChat/supervisord.ini
fi
CMD="/data/envs/llama/bin/supervisord -c ${CONFIG}"
PID="/tmp/${NAME}.pid"


wait_for_pid () {
    try=0
    while test $try -lt 30 ; do
        case "$1" in
            'created')
            if [ -f "$2" ] ; then
                try=''
                break
            fi
            ;;

            'removed')
            if [ ! -f "$2" ] ; then
                try=''
                break
            fi
            ;;
        esac

        echo -n .
        try=`expr $try + 1`
        sleep 1

    done

}


get_pid() {
    if [ -f ${PID} ]; then
        pid=`cat ${PID}`
    else
        pid=`ps aux | grep "supervisord" | grep -i "fastchat" | grep -v grep | awk -F " " '{print $2}' | head -n 1`
    fi

    echo $pid
}


case "$1" in
    start)
        echo -n "Starting ${NAME} "

        ulimit -n 10240
        ulimit -u 40960
        
        ${CMD}
        if [ $? != 0 ] ; then
            echo " failed"
            exit 1
        fi

        wait_for_pid created "$PID"

        if [ -n "$try" ] ; then
            echo " failed"
            exit 1
        else
            echo " done"
        fi
    ;;
    stop)
        pid=$( get_pid )
        kill ${pid}
        wait_for_pid removed ${PID}
        rm -f ${PID}
        echo "Gracefully shutting down ${NAME}, PID ${pid}"
    ;;
    reload)
        pid=$( get_pid )
        echo "Reload ${NAME}: ${pid}"
        kill -s HUP ${pid}
    ;;
    status)
        pid=$( get_pid )
        echo "PID ${pid}"
    ;;
    restart)
        $0 stop
        sleep 2
        $0 start
    ;;
    *)
        echo "Usage: $0 {start|stop|restart|reload|status}"
        exit 1
    ;;

esac
