#!/bin/bash

if [ -f /etc/gw-init ] ; then
  echo "Exiting - instance is already initialised"
  exit 0
fi

export PATH="/usr/local/sbin:/usr/local/bin:/opt/local/sbin:/opt/local/bin:/usr/sbin:/usr/bin:/sbin"

echo "Initialising Gateway Node"

EXTERNAL_NIC=`netstat -rn -f inet | grep ^default | awk '{print $NF}'`
INTERNAL_NIC=`netstat -rn -f inet | grep "^[0-9]" | grep -v "lo0" | grep -v $EXTERNAL_NIC | awk '{print $NF}'`

# Set up ipnat

echo "map $EXTERNAL_NIC 0/0 -> 0/32" > /etc/ipf/ipnat.conf
routeadm -u -e ipv4-forwarding
svcadm enable ipfilter

# Reconfigure OpenSSH to listen on internal IP only
INTERNAL_IP=`ipadm show-addr -p -o addr $INTERNAL_NIC/_a | sed 's/\/.*//g'`
TEMPFILE=`mktemp`
cat /etc/ssh/sshd_config | perl -pi -e "s/^ListenAddress.*/ListenAddress $INTERNAL_IP/g" > $TEMPFILE
cat $TEMPFILE > /etc/ssh/sshd_config
rm -f $TEMPFILE
svcadm restart ssh

# Install ucarp
/opt/local/bin/pkgin -y up
/opt/local/bin/pkgin -y install ucarp

mkdir -p /opt/local/etc/ucarp
cat <<EOF > /opt/local/etc/ucarp/ucarp.options
--daemonize
--interface=$INTERNAL_NIC
--srcip=$INTERNAL_IP
--vhid=${ucarp_vhid}
--pass=${ucarp_pass}
--addr=${ucarp_vip}
--upscript=/opt/local/etc/ucarp/vip-up.sh
--downscript=/opt/local/etc/ucarp/vip-down.sh
--shutdown
EOF

cat <<'EOF' > /opt/local/etc/ucarp/vip-up.sh
#!/bin/bash

NIC=$1
IP=$2
BITS=`ipadm show-addr -p -o addr $NIC/_a | sed 's/.*\///g'`

ipadm create-addr -t -T static -a $IP/$BITS $NIC/ucarp0

EOF
chmod 755 /opt/local/etc/ucarp/vip-up.sh

cat <<'EOF' > /opt/local/etc/ucarp/vip-down.sh
#!/bin/bash

NIC=$1

ipadm delete-addr $NIC/ucarp0

EOF
chmod 755 /opt/local/etc/ucarp/vip-down.sh

cat <<'EOF' > /opt/local/etc/ucarp/ucarp-start.sh
#!/bin/sh

. /lib/svc/share/smf_include.sh

UCARP_BINARY=/opt/local/sbin/ucarp
UCARP_OPTIONS=/opt/local/etc/ucarp/ucarp.options
UCARP_PIDFILE==/var/run/ucarp.pid

if [ ! -f $UCARP_OPTIONS ]; then
    echo "$UCARP_OPTIONS does not exist" >&2
    exit $SMF_EXIT_ERR_CONFIG
fi

case "$1" in
    start)
        $UCARP_BINARY $(cat $UCARP_OPTIONS | grep -v ^#)
        ;;
    stop)
        smf_kill_contract $2 TERM
        ;;
    *)
        echo "Usage: $0 { start | stop  }"
        exit 1
        ;;
esac

exit $SMF_EXIT_OK
EOF
chmod 755 /opt/local/etc/ucarp/ucarp-start.sh

cat <<'EOF' > /opt/local/etc/ucarp/ucarp-smf.xml
<?xml version='1.0'?>
<!DOCTYPE service_bundle SYSTEM '/usr/share/lib/xml/dtd/service_bundle.dtd.1'>
<service_bundle type='manifest' name='export'>
  <service name='network/ucarp' type='service' version='0'>
    <create_default_instance enabled='true'/>
    <single_instance/>
    <dependency name='network' grouping='require_any' restart_on='error' type='service'>
      <service_fmri value='svc:/milestone/network'/>
    </dependency>
    <method_context>
      <method_credential group='root' user='root'/>
    </method_context>
    <exec_method name='start' type='method' exec='/opt/local/etc/ucarp/ucarp-start.sh start' timeout_seconds='60'/>
    <exec_method name='stop' type='method' exec='/opt/local/etc/ucarp/ucarp-start.sh stop %{restarter/contract}' timeout_seconds='60'/>
    <property_group name='application' type='application'/>
    <stability value='Evolving'/>
    <template>
      <common_name>
        <loctext xml:lang='C'>ucarp service</loctext>
      </common_name>
    </template>
  </service>
</service_bundle>
EOF
svccfg import /opt/local/etc/ucarp/ucarp-smf.xml

touch /etc/gw-init

