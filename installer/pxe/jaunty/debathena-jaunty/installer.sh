#!/bin/sh

cd /debathena-jaunty

touch preseed

pxetype=""

netconfig () {
  echo "Configuring network..."
  mp=/debathena-jaunty
  export IPADDR NETMASK GATEWAY SYSTEM CONTROL
  while [ -z "$IPADDR" ] ; do
    echo -n "Enter IP address: "
    read IPADDR
  done
  NETMASK=`$mp/athena/netparams -f $mp/athena/masks $IPADDR|cut -d\  -f 1`
  net=`$mp/athena/netparams -f $mp/athena/masks $IPADDR|cut -d\  -f 2`
  bc=`$mp/athena/netparams -f $mp/athena/masks $IPADDR|cut -d\  -f 3`
  GATEWAY=`$mp/athena/netparams -f $mp/athena/masks $IPADDR|cut -d\  -f 4`
  maskbits=`$mp/athena/netparams -f $mp/athena/masks $IPADDR|cut -d\  -f 5`

  echo "Autoconfigured settings:"
  echo "  Netmask bits: $maskbits"
  echo "  Broadcast: $bc"
  echo "  Gateway: $GATEWAY"
  echo -n "Are these OK? [Y/n]: "; read response
  case $response in
    y|Y|"") ;;
    *) 
    echo -n "Netmask bits [$maskbits]: "; read r; if [ "$r" ] ; then maskbits=$r ; fi
    echo -n "Broadcast [$bc]: "; read r; if [ "$r" ] ; then bc=$r ; fi
    echo -n "Gateway [$GATEWAY]: "; read r; if [ "$r" ] ; then GATEWAY=$r ; fi
    esac

  # We can not set the hostname here; running "debconf-set netcfg/get_hostname"
  # causes fatal reentry problems.  Setting values directly with preseeding
  # also fails, as the DHCP values override it.
  echo "Killing dhcp client."
  killall dhclient
  echo "Running: ip addr flush dev eth0"
  ip addr flush dev eth0
  echo "Running: ip addr add $IPADDR/$maskbits broadcast $bc dev eth0"
  ip addr add $IPADDR/$maskbits broadcast $bc dev eth0
  echo "Flushing old default route."
  route delete default 2> /dev/null
  echo "Running: route add default gw $GATEWAY"
  route add default gw $GATEWAY
  echo "Replacing installer DHCP nameserver with MIT nameservers."
  sed -e '/nameserver/s/ .*/ 18.72.0.3/' < /etc/resolv.conf > /etc/resolv.conf.new
  echo "nameserver	18.70.0.160" >> /etc/resolv.conf.new
  echo "nameserver	18.71.0.151" >> /etc/resolv.conf.new
  mv -f /etc/resolv.conf.new /etc/resolv.conf
}

# Color strings. If the tput abstraction layer gives an error, then no string is fine.
tput_noerr () {
    tput "$@" 2>/dev/null
}
nnn=`tput_noerr sgr0`                                  # Normal
rrr=`tput_noerr bold``tput_noerr setaf 1`              # Red, bold
ccc=`tput_noerr setaf 6`                               # Cyan
ddd="${rrr}`tput_noerr setab 7`"                       # "Blood on concrete"
ddb="${rrr}`tput_noerr setab 7``tput_noerr blink`" 


echo "Welcome to Athena."
echo

while [ -z "$pxetype" ] ; do
  echo "Choose one:"
  echo
  echo "  1: Perform an unattended ${ccc}debathena-cluster${nnn} install, ${rrr}ERASING your"
  echo "     ENTIRE DISK${nnn}. This option is only intended for people setting up"
  echo "     public cluster machines maintained by IS&T/Athena. If you select"
  echo "     this option, you hereby agree with the license terms at:"
  echo "     <http://dlc.sun.com/dlj/DLJ-v1.1.txt>,"
  echo "     Sun's Operating System Distributor License for Java version 1.1."
  echo
  echo "  2: Do a ${ccc}normal Debathena install${nnn}.  You'll need to answer normal Ubuntu"
  echo "     install prompts, and then the Athena-specific prompts, including"
  echo "     choosing which flavor of Debathena you'd like (e.g., private workstation)."
  echo
  echo "  3: Punt to a completely ${ccc}vanilla install of Ubuntu 9.04${nnn} (Jaunty Jackalope)."
  echo "     (Note: locale and keyboard have already been set.)"
  echo
  echo "  4: /bin/sh (for rescue purposes)"
  echo
  echo -n "Choose: "
  read r
  case "$r" in
    1)
      echo "Debathena CLUSTER it is."; pxetype=cluster ;;
    2)
      echo "Normal Debathena install it is."; pxetype=choose ;;
    3)
      echo "Vanilla Ubuntu it is."; pxetype=vanilla;;
    4)
      echo "Here's a shell.  You'll return to this prompt when done."
      /bin/sh;;
    *)
      echo "Choose one of the above, please.";;
  esac
done

##############################################################################

if [ vanilla = $pxetype ] ; then
  echo "WARNING: if you let the system default to using a DHCP address, this"
  echo "may not work for you, as you won't be able to reach the off-campus"
  echo "Ubuntu repositories.  If you cancelled that and configured manually,"
  echo "or otherwise believe you have a functional address, you can continue."
  echo "Would you like to configure a static address before switching back to"
  echo -n "a vanilla Ubuntu install?  [y/N]: "
  while : ; do
    read r
    case "$r" in
      N*|n*|"") break;;
      y*|Y*) netconfig; break;;
    esac
    echo -n "Choose: [y/N]: "
  done

  echo "Starting normal Ubuntu install in five seconds."
  sleep 5
  exit 0
fi

if [ cluster = $pxetype ] ; then
  cat << EOF

************************************************************
               ${ddb}DESTROYS${nnn}
${rrr}THIS PROCEDURE ${ddd}DESTROYS${nnn}${rrr} THE CONTENTS OF THE HARD DISK.${nnn}
               ${ddb}DESTROYS${nnn}

IF YOU DO NOT WISH TO CONTINUE, REBOOT NOW.

************************************************************

EOF
  echo "Installing autoinstall preseed file."
  egrep -v '(^$|^#)' < preseed.autoinstall >> preseed
fi

# Set up a usable static network config, since the DHCP address is not very useful.
netconfig

# Shovel in the generically useful preseed stuff regardless.
egrep -v '(^$|^#)' < preseed.common >> preseed
# ...and the specified network config.
cat >> preseed <<EOF
d-i netcfg/get_nameservers string 18.72.0.3
d-i netcfg/get_ipaddress string $IPADDR
d-i netcfg/get_netmask string $NETMASK
d-i netcfg/get_gateway string $GATEWAY
d-i netcfg/confirm_static boolean true
EOF

# This is used by the final installer step.
# A hardcoded number is used as DNS may still be iffy.
echo "Fetching Debathena postinstaller."
# 18.92.2.195 = OLD athena10.mit.edu
# 18.9.60.73 = NEW athena10.mit.edu
wget http://18.9.60.73/install-debathena.sh

# Let the postinstall know what we are up to.
echo "$pxetype" > $mp/pxe-install-flag

echo "Initial Debathena installer complete; exiting preconfig to start main install."
echo "Hit return to continue."
read r
exit 0
