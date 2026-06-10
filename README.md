# Samsung M2020 CUPS container

Runs Samsung's proprietary x86_64 SPL3 filter in an Ubuntu 24.04 CUPS container. This is useful for an ARM64 print server such as an Orange Pi, using QEMU/binfmt for amd64 emulation.

## Architecture

```mermaid
flowchart LR
    Client[Network clients] -->|IPP, TCP 631| CUPS
    Client -.->|mDNS discovery, UDP 5353| Avahi

    subgraph Host[ARM64 host]
        Avahi[Avahi service]
        QEMU[QEMU amd64 binfmt emulation]

        subgraph Container[Docker container: linux/amd64]
            CUPS[CUPS print server]
            Driver[Samsung x86_64 SPL3 driver]
            CUPS --> Driver
        end

        USB[/dev/bus/usb device mount]
        Config[(cups-state volume<br/>/etc/cups)]
        Spool[(cups-spool volume<br/>/var/spool/cups)]

        QEMU --> Container
        Config --> CUPS
        Spool --> CUPS
        Driver --> USB
    end

    USB --> Printer[Samsung M2020]
    Avahi -.->|advertises IPP queue| CUPS
```

The driver archive, `cupsd.conf`, and `entrypoint.sh` are copied into the image at build time. At runtime, only `/dev/bus/usb` and the two named CUPS volumes are mounted. Host networking exposes CUPS directly on TCP port 631; Avahi remains on the host and uses multicast UDP port 5353.

## Prepare

Install Docker Engine with the Compose plugin, Avahi, and amd64 emulation on the host:

```sh
sudo apt install avahi-daemon avahi-utils
sudo docker run --privileged --rm tonistiigi/binfmt --install amd64
sudo systemctl disable --now cups cups.socket cups.path
```

Download the Samsung Unified Linux Driver into the repository root:

```sh
./download-driver.sh
```

The script downloads `uld_V1.00.39_01.17.tar.gz` from the [Samsung Download Center](https://downloadcenter.samsung.com/content/DR/201704/20170407143829533/uld_V1.00.39_01.17.tar.gz) and verifies its pinned SHA-512 checksum. The maintained [AUR packaging recipe](https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=samsung-unified-driver) is a useful secondary reference for the upstream URL and checksum. The archive is proprietary and intentionally excluded from Git.

Find the printer URI and configure the environment:

```sh
lpinfo -v | grep 'usb://Samsung/M2020'
cp .env.example .env
sudo editor .env
```

## Build and run

```sh
sudo docker compose build
sudo docker compose up -d
sudo install -m 0644 avahi-samsung-m2020.service /etc/avahi/services/
sudo systemctl restart avahi-daemon
```

Test printing:

```sh
sudo docker compose exec cups lpstat -t
sudo docker compose exec cups lp -d Samsung_M2020 /usr/share/cups/data/testprint
```

Clients can use `ipp://HOSTNAME.local:631/printers/Samsung_M2020`. Avahi runs on the host and advertises this CUPS queue over mDNS/DNS-SD.

The repository files are independent of the proprietary Samsung driver license. Review the license included in the downloaded archive before redistribution.
