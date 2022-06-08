# Kickstart file for a minimal install

# https://pykickstart.readthedocs.io/en/latest/kickstart-docs.html
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/performing_an_advanced_rhel_installation/kickstart-commands-and-options-reference_installing-rhel-as-an-experienced-user#kickstart-commands-for-installation-program-configuration-and-flow-control_kickstart-commands-and-options-reference
# ksvalidator -vRHEL8 kickstart.cfg

cmdline
cdrom
reboot

keyboard --vckeymap=us
lang en_US.UTF-8
timezone "${system_timezone}" --utc

rootpw --lock
user --name "${admin_user_name}" --groups wheel --password "${admin_user_pwd}"
sshkey --username "${admin_user_name}" "${admin_public_key}"
user --name "${packer_user_name}" --password "${packer_user_pwd}"
sshkey --username "${packer_user_name}" "${packer_public_key}"

eula --agreed
skipx
firewall --enabled --ssh
selinux --enforcing
authselect select sssd
network --activate --device=enp0s2 --noipv6 --hostname="${hostname}"

zerombr
clearpart --all --initlabel
part /boot --fstype=xfs --size=512 --label=boot
part pv.01 --grow --size=1
volgroup vg.01 --pesize=4096 pv.01
logvol / --fstype=xfs --name=root --vgname=vg.01 --size=10240 --grow
logvol /home --fstype=xfs --name=home --vgname=vg.01 --size=1024 --fsoptions="nodev"
logvol /tmp --fstype=xfs --name=tmp --vgname=vg.01 --size=1024 --fsoptions="nodev,noexec,nosuid"
logvol /var/tmp --fstype=xfs --name=var_tmp --vgname=vg.01 --size=1024 --fsoptions="nodev,nosuid,noexec"
logvol /var --fstype=xfs --name=var --vgname=vg.01 --size=3072
logvol /var/log --fstype=xfs --name=var_log --vgname=vg.01 --size=1024
logvol /var/log/audit --fstype=xfs --name=var_log_audit --vgname=vg.01 --size=512
logvol swap --name=swap --vgname=vg.01 --size=1024

bootloader --location=mbr --timeout=3 --password "${admin_user_pwd}"

%addon com_redhat_kdump --disable
%end

%addon org_fedora_oscap
content-type = scap-security-guide
# https://static.open-scap.org/ssg-guides/ssg-rhel8-guide-cis_server_l1.html
profile = xccdf_org.ssgproject.content_profile_cis_server_l1
%end

%packages
@minimal install
open-vm-tools
pam_ssh_agent_auth
python3
python3-pip
python3-setuptools
%end

%post
echo "Randomizing ${packer_user_name} password"
openssl rand -base64 48 | passwd --stdin ${packer_user_name}

echo "Randomizing ${admin_user_name} password"
openssl rand -base64 48 | passwd --stdin ${admin_user_name}

echo "Enabling fastest mirror logic and updating cache"
echo 'fastestmirror=1' >> /etc/dnf/dnf.conf
dnf makecache

echo "Updating system"
dnf update -y

echo "Cleaning DNF cache"
dnf clean all

echo "Enable periodic trim of SSD storage"
systemctl enable fstrim.timer

echo "Enabling sudo via (remote) SSH agent; requires pam_ssh_agent_auth installed"
cp "/home/${admin_user_name}/.ssh/authorized_keys" /etc/security/authorized_keys
chown root:root /etc/security/authorized_keys
echo 'Defaults env_keep += "SSH_AUTH_SOCK"' >> /etc/sudoers
sed -i '2i auth       sufficient   pam_ssh_agent_auth.so  file=/etc/security/authorized_keys' /etc/pam.d/sudo

echo "CIS Level1 pass2 (just to be sure)"
oscap xccdf eval --fetch-remote-resources --profile xccdf_org.ssgproject.content_profile_cis_server_l1 --report eval_report.html --results eval_results.xml /usr/share/xml/scap/ssg/content/ssg-rl8-ds.xml
oscap xccdf remediate --fetch-remote-resources --results remediate.out eval_results.xml /usr/share/xml/scap/ssg/content/ssg-rl8-ds.xml
%end
