#!/bin/bash
set -o pipefail
echo "**************************"
echo "* Starting Domain' Controller "
echo "**************************"

ulimit -n 8192
export SMB_INIT_FLAG_FILE=/var/log/samba/smb-service.init
export DOMAIN_NAME_LOWERCASE=`echo ${AD_REALM} | awk '{print tolower($0)}' `
export LOG_FILE=/var/log/samba/log.smbd
export KRB_CONF_TARGET=/etc/krb5.conf
touch $LOG_FILE

initService() {
  echo "Applay init scripts START"
  # Provisioning
  samba-tool domain provision \
    --domain ${AD_DOMAIN} \
    --realm=${AD_REALM} \
    --adminpass=${AD_ADMIN_PASSWORD} \
    --server-role=dc \
    --use-rfc2307 \
    --dns-backend=SAMBA_INTERNAL
    
  RESOLV_CONF_TARGET=/etc/resolv.conf
  RESOLV_CONF_SOURCE=/opt/init/resolv.conf
  cp -f /opt/init/resolv.conf.txt $RESOLV_CONF_SOURCE
  sed -i "s|DOMAIN_NAME_LOWERCASE|${DOMAIN_NAME_LOWERCASE}|g" $RESOLV_CONF_SOURCE
  cp -f $RESOLV_CONF_SOURCE $RESOLV_CONF_TARGET
  echo "Current '${RESOLV_CONF_TARGET}' file"
  echo "---------------------------------"
  cat $RESOLV_CONF_TARGET
  echo "---------------------------------"
  cp -f /var/lib/samba/private/krb5.conf $KRB_CONF_TARGET
  echo "Current '${KRB_CONF_TARGET}' file"
  echo "---------------------------------"
  cat $KRB_CONF_TARGET
  echo "---------------------------------"
  
  touch $SMB_INIT_FLAG_FILE
  echo "Applay init scripts END"
}

startService() {
  /usr/sbin/samba --foreground --no-process-group &
}


if [ "$(ls -A $SMB_INIT_FLAG_FILE)" ]; then
  echo "Database is ready."
else
  echo "Init service..."
  initService
fi

startService
tail -f $LOG_FILE
