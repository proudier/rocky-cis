# KVM image for Rocky Linux w/ CIS Level 1

This repository hold a Packer template for a CIS Level 1 compliant Rocky Linux (RHEL) KVM/QEMU virtual machine.

Compared to other implementations that run an Ansible playbook, as a second setup phase to harden the system (thus leaving the system exposed until Ansible is ran), this implementation hardens the system as part of the Anaconda installation process (ie. before the first boot).

The image is effectively 'passwordless':
- SSH won't accept passwords for authentification (block remote access with passwords)
- Users have a random password that nobody knows (block local access with passwords)
- Local `sudo` is made possible with [PAM SSH Agent](https://github.com/jbeverly/pam_ssh_agent_auth).

## Content of resulting image

- Rocky Linux minimal install with CIS applied
- Python3 for later management with Ansible
- An admin user with the login and public key provided at build time; its password has been randomized during the build process
- A leftover Packer user with no `sudo` access and a randomized password


## Building the VM image

### Pre-requisite

Required on the build host:
- [Packer](https://www.packer.io/)
- QEMU/KVM

### User configuration

- Create a `user.auto.pkrvars.hcl` file at the root of this repository that follows [this format](https://www.packer.io/guides/hcl/variables#from-a-file)
- Populate values for the variables declared in [variables.pkr.hcl](variables.pkr.hcl)

### Building

```bash
# Packer refuses to run if `packer_output` already exits
rm -fr packer_output
packer build -timestamp-ui . | tee packer.log
```

The output VM image is `packer_output/packer-vm`.

Build logs are available in the image under `/var/log/anaconda` in the image.

## Using the image

Use the tool you like to create a VM from the image. Here's an example with `virt-install`

```
virt-install --name rockycis --memory 1536 --vcpus 2 --import --boot hd --os-variant rocky8.6 --disk path=packer_output/packer-vm,driver.discard=unmap --network network=default,model=virtio --graphics none --virt-type kvm --cpu host-passthrough --rng backend=/dev/random,model=virtio
```

You **must** use SSH agent forwarding to be able to `sudo` in the VM. Read more on PAM SSH Agent [here](https://github.com/jbeverly/pam_ssh_agent_auth).
```
ssh -A admin@rockycis
```


## Design notes

A `packer` user is created so the Packer communicator can connect to the VM and detect when it can be shutdown.
Because CIS prevent password auth when SSHing, a SSH key is required this user. It's generated randomly using at build time.
Currently, this user is left activated in the output image. It's password is randomized using `openssl`.
