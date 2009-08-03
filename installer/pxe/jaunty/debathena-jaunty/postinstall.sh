#!/bin/sh

# This is only invoked when the relevant preseed entry is passed in
# during the preinstall questioning.  (Thus, not for vanilla installs.)

cp /debathena-jaunty/preseed /target/root/debathena.preseed
cp /debathena-jaunty/install-debathena.sh /target/root
if test -f /debathena-jaunty/pxe-install-flag ; then
  cp /debathena-jaunty/pxe-install-flag /target/root/pxe-install-flag
fi

chvt 5
chroot /target sh /root/install-debathena.sh < /dev/tty5 > /dev/tty5 2>&1
# This approach fails due to lingering processes keeping the
# pipeline open and the script hung.
# chroot /target sh /root/install-debathena.sh < /dev/tty5 2>&1 \
#     | chroot /target tee /var/log/athena-install.log > /dev/tty5
sleep 5
chvt 1
