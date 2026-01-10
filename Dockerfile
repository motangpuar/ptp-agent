FROM fedora:39

RUN dnf install -y linuxptp iproute procps-ng && \
    dnf clean all && \
    rm -rf /var/cache/dnf

COPY entrypoint.sh /usr/local/bin/
COPY ptp4l.conf /etc/ptp4l.conf

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
