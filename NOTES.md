
# Developer's notes

## QA checklist

- Can SSH as admin using SSH key
- Can update system
(- Cannot SSH as packer user using SSH key)

## Potential improvements

In random orders:
- Randomize `packer_user_pwd` at Packer level (so it's totally unpredictible out of the build host)
- Delete packer user at end of build
- Grep the installation logs for error and warning for visibility; currently what happens in `%post` is hidden (that's standard Anaconda behavior)
- Generate a CIS compliance report as last step of the build
- Generate a per build SSH key for Packer user (requires change on `sshkey` plugin)

First boot (out of Packer):
- Regenerate SSH host key
- Remove packer build user `userdel --force --remove --selinux-user "$ADMIN_USER_NAME"`

CIS Level 2:
- Improve the `sshkey` plugin so it can generate a key compliant with crypto policy `FUTURE`
- Find Rocky Linux mirrors using TLS keys compliant with crypto policy `FUTURE`
- ...

### virt-install commands

```
IMG=packer_output/packer-vm

# DEV
virt-install --name donnager2 --memory 1536 --vcpus 2 --import --boot hd --os-variant rocky8.6 --disk path=$IMG,driver.discard=unmap --network network=default,model=virtio --graphics none --virt-type kvm --cpu host-passthrough --rng backend=/dev/random,model=virtio

--filesystem /tmp/donnager,/hostfs
mount -t 9p hostfs /mnt

# PRD
sudo virt-install --name donnager --memory 1536 --vcpus 2 --import --boot hd --os-variant rocky8.6 --disk path=/srv/virt/donnager.qcow2,driver.discard=unmap --network none --graphics none --virt-type kvm --cpu host-passthrough --rng backend=/dev/random,model=virtio --hostdev type=pci,name=05:00.0 --autostart --dry-run
```


### OSCAP

```
oscap xccdf eval --fetch-remote-resources --profile xccdf_org.ssgproject.content_profile_cis_server_l1 --report eval_report.html --results eval_results.xml /usr/share/xml/scap/ssg/content/ssg-rl8-ds.xml
oscap xccdf remediate --fetch-remote-resources --results remediate.out eval_results.xml /usr/share/xml/scap/ssg/content/ssg-rl8-ds.xml
oscap xccdf generate fix --profile xccdf_org.ssgproject.content_profile_cis_server_l1 --fix-type bash --output scan_remediations.sh scan_results.xml
```

## CIS Level 2

[Profile](https://static.open-scap.org/ssg-guides/ssg-rhel8-guide-cis.html): `xccdf_org.ssgproject.content_profile_cis`

Changing mirrors:
```
echo "Selecting a mirror compatible with FUTURE crypto policy"
sed -i -e "s|mirrorlist=|#mirrorlist=|g" /etc/yum.repos.d/Rocky-*
sed -i -e "s|#baseurl=http://dl.rockylinux.org/\$contentdir|baseurl=https://mirrors.rit.edu/rocky|g" /etc/yum.repos.d/Rocky-*
```

[Crypto policy](https://static.open-scap.org/ssg-guides/ssg-rhel8-guide-cis.html#xccdf_org.ssgproject.content_rule_configure_crypto_policy)

```
update-crypto-policies --show
fips-mode-setup --check
```

## SELinux

Packages
- policycoreutils-python-utils
- setools-console
- setools
- setroubleshoot
- setroubleshoot-server

## Snippets

```
provisioner "ansible" {
  playbook_file = "ansible-protonvpn.yml"
  use_proxy     = false
  extra_arguments = [
    "--become",
    "-e ansible_become_pass=${var.packer_user_pwd}"
  ]
}
```

```
provisioner "shell" {
  script          = "final_steps.sh"
  execute_command = "echo '${var.packer_user_pwd}' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
  remote_folder   = "/home/${var.packer_user_name}"
  environment_vars = [
    "ADMIN_USER_NAME=${var.admin_user_name}"
  ]
}
```

Encrypt passwords https://pykickstart.readthedocs.io/en/latest/commands.html#rootpw to see how to create
```
rootpw --iscrypted $6$/0RYeeRdK70ynvYz$jH2ZN/80HM6DjndHMxfUF9KIibwipitvizzXDH1zW.fTjyD3RD3tkNdNUaND18B/XqfAUW3vy1uebkBybCuIm0
user --name=admin --groups=wheel --password=$6$Ga6ZnIlytrWpuCzO$q0LqT1USHpahzUafQM9jyHCY9BiE5/ahXLNWUMiVQnFGblu0WWGZ1e6icTaCGO4GNgZNtspp1Let/qpM7FMVB0 --iscrypted
bootloader --location=mbr --append="crashkernel=auto rhgb quiet" --password=$6$zCPaBARiNlBYUAS7$40phthWpqvaPVz3QUeIK6n5qoazJDJD5Nlc9OKy5SyYoX9Rt4jFaLjzqJCwpgR4RVAEFSADsqQot0WKs5qNto0
