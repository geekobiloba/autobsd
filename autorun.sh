# SPDX-License-Identifier: BSD 2-Clause

# Shadow-patch bsdinstall's mount script
cp -fv /usr/libexec/bsdinstall/mount /tmp/autobsd_mount
cat <<'EOF' >> /tmp/autobsd_mount
#
# AutoBSD: Mount patched bsdinstall mount script
#
mkdir -pv                           ${BSDINSTALL_CHROOT}/etc/installerconfig.d
mount_nullfs /etc/installerconfig.d ${BSDINSTALL_CHROOT}/etc/installerconfig.d
EOF
mount_nullfs /tmp/autobsd_mount /usr/libexec/bsdinstall/mount

# Shadow-patch bsdinstall's umount script
cp -fv /usr/libexec/bsdinstall/umount /tmp/autobsd_umount
cat <<'EOF' >> /tmp/autobsd_umount
#
# AutoBSD: Unmount patched bsdinstall mount script
#
umount ${BSDINSTALL_CHROOT}/etc/installerconfig.d
rmdir  ${BSDINSTALL_CHROOT}/etc/installerconfig.d
EOF
mount_nullfs /tmp/autobsd_umount /usr/libexec/bsdinstall/umount

# Run bsdinstall, then reboot when everything goes well
bsdinstall script /etc/installerconfig && reboot

# vim:ft=sh:
