#!/bin/sh
ledstate=`xset q 2>/dev/null | grep LED | sed s/[^1-9]//g`
case "$ledstate" in 
    '1')
        echo "C."
    ;;
    '2')
        echo ".N"
    ;;
    '3')
        echo "CN"
    ;;
    *)
        echo ".."
esac

