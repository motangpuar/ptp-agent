#!/bin/bash
set -e

: ${PTP_INTERFACE:="ens7f0"}
: ${PTP_DOMAIN:="24"}
: ${TX_TIMEOUT:="100"}

echo "[INFO] PTP Configuration:"
echo "  Interface: $PTP_INTERFACE"
echo "  Domain: $PTP_DOMAIN"
echo "  TX Timeout: $TX_TIMEOUT"

if [ ! -e "/sys/class/net/$PTP_INTERFACE" ]; then
    echo "[ERROR] Interface $PTP_INTERFACE does not exist"
    exit 1
fi

# Update domain and timeout in [global] section only
sed -i "/^\[global\]/,/^\[/ s/domainNumber.*/domainNumber            $PTP_DOMAIN/" /etc/ptp4l.conf
sed -i "/^\[global\]/,/^\[/ s/tx_timestamp_timeout.*/tx_timestamp_timeout    $TX_TIMEOUT/" /etc/ptp4l.conf

# Replace only the interface section name (not [global])
sed -i "s/^\[ens7f0\]/[$PTP_INTERFACE]/" /etc/ptp4l.conf

echo "[INFO] Generated config:"
cat /etc/ptp4l.conf

echo "[INFO] Starting ptp4l on $PTP_INTERFACE"
/usr/sbin/ptp4l -f /etc/ptp4l.conf -m &
PTP4L_PID=$!

sleep 3

if ! kill -0 $PTP4L_PID 2>/dev/null; then
    echo "[FAIL] ptp4l failed to start"
    exit 1
fi

echo "[SUCCESS] ptp4l started (PID: $PTP4L_PID)"

echo "[INFO] Starting phc2sys"
/usr/sbin/phc2sys -a -r -r -n $PTP_DOMAIN -m &
PHC2SYS_PID=$!

sleep 2

if ! kill -0 $PHC2SYS_PID 2>/dev/null; then
    echo "[FAIL] phc2sys failed to start"
    kill $PTP4L_PID
    exit 1
fi

echo "[SUCCESS] phc2sys started (PID: $PHC2SYS_PID)"

cleanup() {
    echo "[INFO] Shutting down PTP services"
    kill $PTP4L_PID $PHC2SYS_PID 2>/dev/null || true
    wait $PTP4L_PID $PHC2SYS_PID 2>/dev/null || true
}

trap cleanup TERM INT

wait
