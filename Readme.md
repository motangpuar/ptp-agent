# PTP Agent Container for OKD/OpenShift

Containerized PTP daemon (ptp4l + phc2sys) for time synchronization on real-time Kubernetes nodes.

## Files

- `Dockerfile` - Container image definition
- `entrypoint.sh` - Service startup script with CPU affinity
- `ptp4l.conf` - PTP daemon configuration
- `daemonset.yaml` - Kubernetes deployment manifest

## Build
```bash
podman build -t <registry>/ptp-agent:okd .
podman push <registry>/ptp-agent:okd
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PTP_INTERFACE` | `ens7f0` | Network interface for PTP |
| `PTP_DOMAIN` | `24` | PTP domain number |
| `TX_TIMEOUT` | `100` | TX timestamp timeout (use 100 for Intel E810) |
| `HOUSEKEEPING_CPUS` | `2-27,30-31` | CPUs for PTP processes |

### PTP Configuration

Edit `ptp4l.conf` for advanced settings:
- `time_stamping`: `hardware` or `software`
- `network_transport`: `L2` or `UDPv4`
- `slaveOnly`: Set to `1` for slave mode

## Deploy
```bash
oc apply -f daemonset.yaml
```

Update image reference in `daemonset.yaml` before deploying.

## Verify
```bash
# Check pod status
oc get pods -n kube-system -l app=ptp

# View logs
oc logs -n kube-system -l app=ptp -f

# Check synchronization
oc logs -n kube-system -l app=ptp | grep "master offset"

# Verify CPU affinity
oc exec -n kube-system -l app=ptp -- ps -eLo pid,psr,comm | grep ptp
```

Good sync: `master offset` values under ±100ns

## Requirements

- Hardware PTP support on NIC
- Real-time kernel (optional but recommended)
- Privileged pod security
- Host network access

## Troubleshooting

**Problem**: `ptp4l` fails to start
- Check interface exists: `ip link show $PTP_INTERFACE`
- Verify hardware timestamping: `ethtool -T $PTP_INTERFACE`

**Problem**: High offset values
- Increase `TX_TIMEOUT` to 100 or higher
- Check network path to PTP master
- Verify NIC firmware supports PTP

**Problem**: Node crashes on RT kernel
- Ensure `HOUSEKEEPING_CPUS` excludes isolated CPUs
- Check `/proc/cmdline` for `isolcpus` parameter
- Verify NIC IRQ affinity matches housekeeping CPUs
