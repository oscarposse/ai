#!/bin/sh
# LSN VSFTPD chroot install
# Version 1.0
# August 1, 2005
# Fire Eater <LinuxRockz@gmail.com>
# Released under the GPL License- http://www.fsf.org/licensing/licenses/gpl.txt
##############################################################################
#
IP_Address="`( /sbin/ifconfig | head -2 | tail -1 | awk '{ print $2; }' | tr --delete [a-z]:)`"
My_FTP_User="my_ftp_virtual_user"
My_FTP_Password="my_secret_password"

echo ""
echo "Setting up Vsftpd with non-system user logins"
echo ""
#
#
mv  /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.orig
cat <<EOFVSFTPD> /etc/vsftpd/vsftpd.conf
anon_world_readable_only=NO
anonymous_enable=NO
chroot_local_user=YES
guest_enable=NO
guest_username=ftp
hide_ids=YES
listen=YES
listen_address=$IP_Address
local_enable=YES
max_clients=100
max_per_ip=2
nopriv_user=ftp
pam_service_name=ftp
pasv_max_port=65535
pasv_min_port=64000
session_support=NO
use_localtime=YES
user_config_dir=/etc/vsftpd/users
userlist_enable=YES
userlist_file=/etc/vsftpd/denied_users
xferlog_enable=YES
anon_umask=0027
local_umask=022
async_abor_enable=YES
connect_from_port_20=YES
dirlist_enable=NO
download_enable=NO
EOFVSFTPD

cat /etc/passwd | cut -d ":" -f 1 | sort > /etc/vsftpd/denied_users; mkdir /etc/vsftpd/users
sed -e '/'$My_FTP_User'/d' < /etc/vsftpd/denied_users > /etc/vsftpd/denied_users.tmp
mv /etc/vsftpd/denied_users.tmp /etc/vsftpd/denied_users
chmod 644 /etc/vsftpd/denied_users

cat <<EOFPAMFTP> /etc/pam.d/ftp
auth    required pam_userdb.so db=/etc/vsftpd/accounts
account required pam_userdb.so db=/etc/vsftpd/accounts
EOFPAMFTP

cat <<EOFVSFTPU> /etc/vsftpd/users/$My_FTP_User
dirlist_enable=YES
download_enable=YES
local_root=/var/ftp/virtual_users/$My_FTP_User/
write_enable=YES
EOFVSFTPU

echo $My_FTP_User > /etc/vsftpd/accounts.tmp
echo $My_FTP_Password >> /etc/vsftpd/accounts.tmp
/usr/bin/db_load -T -t hash -f  /etc/vsftpd/accounts.tmp /etc/vsftpd/accounts.db

#
# Set Permissions
#
chmod 600 /etc/vsftpd/accounts.db
if [ /usr/sbin/selinuxenabled ];then
    printf ' Setting up SELinux Boolean (allow_ftpd_anon_write 1) ... '
    /usr/sbin/setsebool -P allow_ftpd_anon_write 1
    printf "Done.\n"
fi
