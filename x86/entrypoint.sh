#!/bin/sh
set -eu

QUEUE_NAME=${QUEUE_NAME:-Samsung_M2020}
: "${DEVICE_URI:?DEVICE_URI must be set}"
PPD=/usr/share/ppd/samsung/Samsung_M2020_Series.ppd

mkdir -p /run/cups /var/spool/cups /var/log/cups /etc/cups/ppd
install -m 0644 /usr/local/share/m2020/cupsd.conf /etc/cups/cupsd.conf
rm -f /run/cups/cups.sock /run/cups/cups.pid

(
    i=0
    while ! lpstat -r >/dev/null 2>&1; do
        i=$((i + 1))
        if [ "$i" -ge 60 ]; then
            echo "CUPS did not become ready" >&2
            exit 1
        fi
        sleep 1
    done

    i=0
    until lpadmin -p "$QUEUE_NAME" -E -v "$DEVICE_URI" -P "$PPD" \
        -D "Samsung Xpress M2020" -L "USB print server" \
        -o media=A4 -o printer-is-shared=true; do
        i=$((i + 1))
        if [ "$i" -ge 30 ]; then
            echo "Unable to configure printer queue" >&2
            exit 1
        fi
        sleep 1
    done
    lpadmin -d "$QUEUE_NAME"
    cupsaccept "$QUEUE_NAME"
    cupsenable "$QUEUE_NAME"
) &

exec /usr/sbin/cupsd -f
