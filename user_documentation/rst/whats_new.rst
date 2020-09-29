.. _whatsnew:

What's New
**********

**This section contains detailed upgrade notes for recent versions**

v0.9.1
======

Major Enhancements
------------------

Support for Oracle Cloud Infrastructure
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

MiCADO now includes support for
`Oracle Cloud Infrastructure <https://www.oracle.com/ca-en/cloud/>`__ !

Provisioning virtual machines in OCI is currently supported by Terraform
in MiCADO. Details on preparing your ADT for use with Oracle can be found
in the :ref:`ociadt` section of the documentation.

Submitter API v2.0
~~~~~~~~~~~~~~~~~~

The MiCADO Submitter RESTful API has been updated to v2.0, to facilitate
better intergration with other tools and platforms. The functionality of
the previous API version has been preserved and limited backwards
compatibility with v1.0 of the API is still maintained in this version.

Expect v1.0 of the API to be deprecated in a future version.


Fixes
-----

Kubernetes Secret Distribution via ADT Policies
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A bug which prevented MiCADO from distributing application secrets defined
in policies within the ADT has been resolved. See the :ref:`secretdist`
section of the documentation for details on how to define and assign secrets
inside an ADT.


Known Issues & Deprecations
---------------------------

Ubuntu 16.04
~~~~~~~~~~~~

This version of MiCADO adds support for the latest Ubuntu 20.04 LTS. Going
forward, MiCADO will deprecate support for Ubuntu 16.04 LTS and focus on
supporting the current long-term support releases of Ubuntu: 18.04 and 20.04


v0.9.0
======

Major Enhancements
------------------

Terraform for Cloud Orchestration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

| Support for `Terraform <https://terraform.io>`__ has been added to MiCADO!
| The TerraformAdaptor currently supports the following cloud resources:

- OpenStack Nova Compute
- Amazon EC2 Compute
- Microsoft Azure Compute
- Google Compute Engine

To use Terraform with MiCADO it must be **enabled** during deployment
of the MiCADO Master, and an appropriate **ADT** should be used.

Improved Credential File Handling
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Cloud credentials are now stored in Kubernetes Secrets on the MiCADO Master.
Additionally, credentials on an already deployed MiCADO can now be updated
or modified using Ansible.

Improved Node Contextualisation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

It is now possible to **insert** contextualisation configurations earlier
in the default *cloud-init #cloud-config* for worker nodes. This extends
the existing **append** functionality to support configuration tasks which
should precede the initialisation of the worker node (joining the Kubernetes
cluster, bringing up the IPSec tunnel, etc...)

Fixes
-----

Zorp Ingress
~~~~~~~~~~~~

The Zorp Ingress Controllers in v0.8.0 were incorrectly being deployed
alongside *every* application, even if the policy did not call for it. This
has now been resolved.

Additionally, these workers were requesting a large amount of CPU and Memory,
which could limit scheduling on the node. Those requests have been lowered to
more reasonable values.

Different Versioned Workers
~~~~~~~~~~~~~~~~~~~~~~~~~~~

In previous versions of MiCADO, deployed worker nodes which did not match
the Ubuntu version of the MiCADO Master would be unable to join the
MiCADO cluster. This has now been resolved.

Known Issues & Deprecations
---------------------------

IPSec and Dropped Network Packets
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

On some network configurations, for example where IPSec protocols ESP (50) and
AH (51) are blocked, important network packets can get dropped in
Master-Worker communications. This might be seen as Prometheus scrapes
failing with the error **context deadline exceeded**, or Workers failing
to join the Kubernetes cluster. To disable the IPSec tunnel securing
Master-Worker communications, it can be stopped by appending
**ipsec stop** to **runcmd** in the default worker node
*cloud-init #cloud-config*.

Compute Node Inputs in ADTs
~~~~~~~~~~~~~~~~~~~~~~~~~~~

The Occopus **input** *interface_cloud* has been deprecated and removed,
as cloud discovery is now based on TOSCA type. It will continue to be
supported (ignored) in this version of MiCADO but may raise warnings or
errors in future versions.

The **input** *endpoint_cloud* has been deprecated in favour of
*endpoint*. Both Terraform and Occopus will support *endpoint_cloud*
in this version of MiCADO but a future version will drop support.

With the above changes in mind, Terraform will support v0.8.0 ADTs
which only include EC2 or Nova Compute nodes. This can be acheieved simply
by changing **interfaces** from *Occopus* to *Terraform*, though it
should be noted:

- Terraform will auto-discover the EC2 endpoint based on the *region_name*
  property, making the *endpoint* input no longer required. The *endpoint*
  input can still be passed in to provide a custom endpoint.
- For some OpenStack configurations, Terraform requires a *network_name*
  as well as *network_id* to correctly identify networks. The *network_name*
  property can be passed in as **properties** or **inputs**
