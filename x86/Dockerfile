FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

# Some ARMv7 QEMU/binfmt combinations reject i386 utime syscalls.
COPY x86/tar-no-utime /usr/local/sbin/tar-no-utime

RUN mv /usr/bin/tar /usr/bin/tar.real \
    && install -m 0755 /usr/local/sbin/tar-no-utime /usr/bin/tar \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        cups \
        cups-filters \
        ca-certificates \
        libcupsimage2 \
        libstdc++6 \
    && mv -f /usr/bin/tar.real /usr/bin/tar \
    && rm /usr/local/sbin/tar-no-utime \
    && rm -rf /var/lib/apt/lists/*

COPY uld_V1.00.39_01.17.tar.gz /tmp/uld.tar.gz

RUN mkdir -p /tmp/uld /opt/smfp-common/printer/bin \
        /opt/smfp-common/printer/lib /usr/share/ppd/samsung \
    && tar --touch --no-same-owner -xzf /tmp/uld.tar.gz -C /tmp/uld \
    && install -m 0755 /tmp/uld/uld/i386/rastertospl \
        /opt/smfp-common/printer/bin/rastertospl \
    && install -m 0644 /tmp/uld/uld/i386/libscmssc.so \
        /opt/smfp-common/printer/lib/libscmssc.so \
    && install -m 0644 \
        /tmp/uld/uld/noarch/share/ppd/Samsung_M2020_Series.ppd \
        /usr/share/ppd/samsung/Samsung_M2020_Series.ppd \
    && ln -s /opt/smfp-common/printer/bin/rastertospl \
        /usr/lib/cups/filter/rastertospl \
    && rm -rf /tmp/uld /tmp/uld.tar.gz

COPY x86/cupsd.conf /usr/local/share/m2020/cupsd.conf
COPY x86/entrypoint.sh /usr/local/sbin/m2020-entrypoint

RUN chmod 0755 /usr/local/sbin/m2020-entrypoint \
    && chmod 0755 /opt/smfp-common/printer/bin/rastertospl \
    && chmod 0644 /opt/smfp-common/printer/lib/libscmssc.so \
    && cupstestppd /usr/share/ppd/samsung/Samsung_M2020_Series.ppd \
    && ldd /opt/smfp-common/printer/bin/rastertospl > /tmp/rastertospl.ldd \
    && ! grep -q 'not found' /tmp/rastertospl.ldd \
    && rm /tmp/rastertospl.ldd

EXPOSE 631/tcp

ENTRYPOINT ["/usr/local/sbin/m2020-entrypoint"]
