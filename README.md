# Automatically install a virtual OpenShift cluster

This is a collection of scripts that in combination with [oaitool][]
automate the process of installing an OpenShift cluster on virtual
hardware.

[oaitool]: https://github.com/larsks/oaitool

## Usage

```
./create-cluster.sh <clustername> <api_vip> <ingress_vip>
```

Where `<api_vip>` and `<ingress_vip>` are addresses on your libvirt
`default` network. It helps if you reserve some address space on your
network for statically allocating addresses. The following network XML
would reduce the DHCP arrange to leave space at both the top and
bottom of the network range:

```
<network>
  <name>default</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.20' end='192.168.122.200'/>
    </dhcp>
  </ip>
</network>
```

Given the above network definition, we might create a new cluster like
this:

```
./create-cluster.sh mycluster 192.168.122.10 192.168.122.11
```

## Requirements & Assumptions

- You must have [oaitool][] installed somewhere in your `$PATH`

- You must have sufficient resources to create at least three nodes
  with the following specifications:

  - 30GB RAM
  - 120GB disk space
  - 8 vcpus

  That's a total of 90GB RAM, 360GB disk space, and 24 vcpus. You can
  probably reduce the RAM and vcpus a bit without impact, but the disk
  space is a hard requirement (the nodes will fail validation with
  less than 120GB of disk).

- These script by default use the base domain `ocp.virt`. It's
  expected you will configure things (e.g., your `/etc/hosts` file) so
  that hostnames in this domain resolve as expected.

  If you create a cluster named `mycluster`, you would minimally need
  the following entries in `/etc/hosts`:

  ```
  <api_vip> api.mycluster.ocp.virt
  <ingress_vip> console-openshift-console.apps.mycluster.ocp.virt oauth-openshift.apps.mycluster.ocp.virt
  ```

## Remote access

You can access the cluster remotely via an ssh SOCKS proxy. From your
local system, create a SOCKS proxy connection to your virtual host
like this:

```
ssh -Nf -D 1080 -l yourusername your.hypervisor.host
```

Now, on your local system, you can set the `https_proxy` environment
variable:

```
export https_proxy=socks5://localhost:1080
```

Any `kubectl` or `oc` commands you run in this shell will respect the
`https_proxy` setting.
