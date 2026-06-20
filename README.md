#   AutoBSD

AutoBSD is a FreeBSD autoinstaller utilizing
[bsdinstall(8)](https://man.freebsd.org/cgi/man.cgi?bsdinstall),
[nuageinit(7)](https://man.freebsd.org/cgi/man.cgi?nuageinit), and
[mfsBSD](https://mfsbsd.vx.sk/).
It simplifies FreeBSD unattended installations in various scenarios,
and can even act as a "detuxifier" to easily turn a Linux machine into FreeBSD,
all with these options:

-   Advanced ZFS or just simple UFS.

-   The shiny new [pkgbase(7)](https://man.freebsd.org/cgi/man.cgi?pkgbase)[^pkgbase]
    or battle-tested distribution sets.

-   Whole system configuration with nuageinit/cloud-init.

##  Quickstart

1.  Use a FreeBSD machine to clone this repo.

2.  Copy these files:

    -   `installerconfig.d/autobsd.conf.sample` as `installerconfig.d/autobsd.conf`
    -   `installerconfig.d/nuageinit/user-data.sample` as `installerconfig.d/nuageinit/user-data`

3.  Edit the resulting files to suit your needs.

4.  Build AutoBSD:

    -   as an ISO:

        ```shell
        doas make iso
        ```

    -   raw image:

        ```shell
        doas make img
        ```

    -   or both:

        ```shell
        doas make all
        ```

##  Configuration

All configurations and their defaults are available
in `installerconfig.d/autobsd.conf.sample`.

##  Hooks

Four optional hooks
can be placed inside the `installerconfig.d/hooks` directory
to extend the installation flow.
They are sourced by the `installerconfig` script independently.

1.  `preamble-start.sh`
    is sourced after all configurations are set
    to allow configuration overrides, among other actions.

    Execution happens in the host (mfsBSD) environment.

2.  `preamble-end.sh`
    is sourced just before disk partitioning and formatting begin.

    Execution happens in the same environment as the previous hook.

3.  `chroot-start.sh`
    is sourced at the start of the chroot script.

    Execution happens inside the chroot environment of the newly installed system,
    inheriting any exported variables from the preamble.

4.  `chroot-end.sh`
    is sourced at the end of the chroot script,
    just before the final dialog.

    Execution happens inside the same environment as the previous hook.

##  Tips

### Build a different FreeBSD version than the build machine

An AutoBSD build normally uses the same FreeBSD version as its build machine.
To override this, use the `DIST_URL` variable, _e.g._:

```shell
doas make DIST_URL=https://download.freebsd.org/snapshots/amd64/16.0-CURRENT all
```

### Offline installation

Offline installation is possible with these snippets:

1.  `installerconfig.d/autobsd.conf`

    ```shell
    autobsd_pkgbase="NO"
    autobsd_fwget="NO"
    ```

2.  `installerconfig.d/nuageinit/user-data`

    ```yaml
    package_update: true
    package_upgrade: true
    packages: []
    ```

Ensure no network dependent action in hooks and nuageinit `runcmd`,
then build with the `EMBED_DIST` variable, _e.g._:

```shell
doas make EMBED_DIST=1 all
```

### Detuxifier

Replacing Debian with FreeBSD is easy.
This is handy on a VPS without any FreeBSD template.

1.  Build an AutoBSD raw image, then upload it to the VPS.

2.  Stop potentially blocking services:

    ```shell
    systemctl stop systemd-udevd.service systemd-udevd-control.socket systemd-udevd-kernel.socket systemd-journald.service systemd-journald.socket systemd-journald-dev-log.socket systemd-timesyncd
    ```

3.  Find the boot device with `lsblk`, then burn AutoBSD to it, _e.g._:

    ```shell
    dd if=AutoBSD-amd64-15.0-RELEASE.img of=/dev/sda conv=fsync,noerror status=progress
    ```

4.  Stop the VPS forcefully,
    then start it again to boot AutoBSD.

##  TODO

- [ ]   Test on Raspberry Pi and write the process in the _Tips_ section.
        Using QEMU to build AutoBSD may be easier in this case.

[^pkgbase]: Only for FreeBSD 15.1 or above.

