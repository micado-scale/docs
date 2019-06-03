.. _deployment:

Deployment
**********

To deploy MiCADO you need a (separate) virtual machine, called MiCADO master. There are two ways of deployment:

* remote: download the Ansible playbook on your local machine, configure the MiCADO master as target machine and run the playbook to perform the deployment remotely.
* local: login to the MiCADO master, download the Ansible playbook, configure the localhost as target machine and run the playbook to perform the deployment locally.

We recommend to perform the installation remotely as all your configuration files are preserved on your machine, i.e. it is easier to repeat the deployment if needed.

Prerequisites
=============

For cloud interfaces supported by MiCADO:

* EC2 (tested on Amazon and OpenNebula)
* Nova (tested on OpenStack)
* CloudSigma
* CloudBroker

For the MiCADO master:

* Ubuntu 16.04
* (Minimum) 2GHz CPU & 3GB RAM & 15GB DISK
* (Recommended) 2GHz CPU & 4GB RAM & 20GB DISK

For the host where the Ansible playbook is executed (differs depending on local or remote):

* Ansible 2.4 or greater
* curl
* jq (to pretty-format API responses)
* wrk (to load test nginx & wordpress demonstrators)

Ansible
-------

Note: Ansible in the Ubuntu 16.04 APT repository is outdated and insufficient (at the time of writing this document)

To install Ansible on Ubuntu 16.04, use these commands:

::

   sudo apt-get update
   sudo apt-get install software-properties-common
   sudo apt-add-repository ppa:ansible/ansible
   sudo apt-get update
   sudo apt-get install ansible

To install Ansible on other operation systems follow the `official installation guide <https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html>`__.

curl
----

To install curl on Ubuntu, use this command:

::

   sudo apt-get install curl

To install curl on other operating systems follow the `official installation guide <https://curl.haxx.se/download.html>`__.

jq
----

To install jq on Ubuntu, use this command:

::

   sudo apt-get install jq

To install jq on other operating systems follow the `official installation guide <https://stedolan.github.io/jq/download/>`__.

wrk
----

To install wrk on Ubuntu, use this command:

::

   sudo apt-get install wrk

To install wrk on other operating systems check the sidebar on the `github wiki <https://github.com/wg/wrk/wiki>`__.

Installation
============

Perform the following steps either on your local machine or on MiCADO master depending on the installation method.

Step 1: Download the ansible playbook.
--------------------------------------

::

   curl --output ansible-micado-0.7.2-rev1.tar.gz -L https://github.com/micado-scale/ansible-micado/releases/download/v0.7.2-rev1/ansible-micado-0.7.2-rev1.tar.gz
   tar -zxvf ansible-micado-0.7.2-rev1.tar.gz
   cd ansible-micado-0.7.2-rev1/

Step 2: Specify cloud credential for instantiating MiCADO workers.
------------------------------------------------------------------

MiCADO master will use this credential against the cloud API to start/stop VM instances (MiCADO workers) to host the application and to realize scaling. Credentials here should belong to the same cloud as where MiCADO master is running. We recommend making a copy of our predefined template and edit it. MiCADO expects the credential in a file, called credentials-cloud-api.yml before deployment. Please, do not modify the structure of the template!

::

   cp sample-credentials-cloud-api.yml credentials-cloud-api.yml
   edit credentials-cloud-api.yml

Edit credentials-cloud-api.yml to add cloud credentials. You will find predefined sections in the template for each cloud interface type MiCADO supports. Fill only the section belonging to your target cloud.

Optionally you can use the `Ansible Vault <https://docs.ansible.com/ansible/2.4/vault.html>`_ mechanism to keep the credential data in an encrypted format. To achieve this, create the above file using Vault with the command

::

    ansible-vault create credentials-cloud-api.yml


This will launch the editor defined in the ``$EDITOR`` environment variable to make changes to the file. If you wish to make any changes to the previously encrypted file, you can use the command

::

    ansible-vault edit credentials-cloud-api.yml

Step 3a: Specify security settings and credentials to access MiCADO.
--------------------------------------------------------------------

MiCADO master will use these security-related settings and credentials to authenticate its users for accessing the REST API and Dashboard.

::

   cp sample-credentials-micado.yml credentials-micado.yml
   edit credentials-micado.yml

Specify the provisioning method for the x509 keypair used for TLS encryption of the management interface in the ``tls`` subtree:

* The 'self-signed' option generates a new keypair with the specified hostname as subject (or 'micado-master' if omitted).
* The 'user-supplied' option lets the user add the keypair as plain multiline strings (in unencrypted format) in the ansible_user_data.yml file under the 'cert' and 'key' subkeys respectively.

Specify the default username and password for the administrative user in the ``authentication`` subtree.

Optionally you may use the Ansible Vault mechanism as described in Step 2 to protect the confidentiality and integrity of this file as well.


Step 3b: (Optional) Specify credentials to use private Docker registries.
-------------------------------------------------------------------------

Set the Docker login credentials of your private Docker registry in which your private containers are stored. We recommend making a copy of our predefined template and edit it. MiCADO expects the docker registry credentials in a file, called credentials-docker-registry.yml. Please, do not modify the structure of the template!

::

   cp sample-credentials-docker-registry.yml credentials-docker-registry.yml
   edit credentials-docker-registry.yml

Edit credentials-docker-registry.yml and add username, password, and registry url. To login to the default docker_hub, leave DOCKER_REPO as is (https://index.docker.io/v1/).

Optionally you may use the Ansible Vault mechanism as described in Step 2 to protect the confidentiality and integrity of this file as well.

Step 4: Launch an empty cloud VM instance for MiCADO master.
------------------------------------------------------------

This new VM will host the MiCADO core services.

**a)** Default port number for MiCADO service is ``443``. Optionally, you can modify the port number stored by the variable called ``web_listening_port`` defined in the ansible playbook file called ``micado-master.yml``.

**b)** Configure a cloud firewall settings which opens the following ports on the MiCADO master virtual machine:

========  =============  ====================
Protocol  Port(s)        Service
========  =============  ====================
 TCP      443*           web listening port (configurable*)
 TCP      22             SSH
 TCP      2379-2380      etcd server
 TCP      6443           kube-apiserver
 TCP      10250-10252    kubelet, kube-controller, kube-scheduler
 UDP      8285 & 8472    flannel overlay network
========  =============  ====================

**NOTE:** ``[web_listening_port]`` should match with the actual value specified in Step 4a.

**NOTE:** MiCADO master has built-in firewall, therefore you can leave all ports open at cloud level.

**c)** Finally, launch the virtual machine with the proper settings (capacity, ssh keys, firewall): use any of aws, ec2, nova, etc command-line tools or web interface of your target cloud to launch a new VM. We recommend a VM with 2 cores, 4GB RAM, 20GB disk. Make sure you can ssh to it (password-free i.e. ssh public key is deployed) and your user is able to sudo (to install MiCADO as root). Store its IP address which will be referred as ``IP`` in the following steps.

Step 5: Customize the inventory file for the MiCADO master.
-----------------------------------------------------------

We recommend making a copy of our predefined template and edit it. Use the template inventory file, called sample-hosts for customisation.

::

   cp sample-hosts hosts
   edit hosts

Edit the ``hosts`` file to set ansible variables for MiCADO master machine. Update the following parameters on the line beginning **micado-master**:

* **ansible_host**: specifies the publicly reachable ip address of MiCADO master. Set the public or floating ``IP`` of the master regardless the deployment method is remote or local. The ip specified here is used by the Dashboard for webpage redirection as well
* **ansible_connection**: specifies how the target host can be reached. Use "ssh" for remote or "local" for local installation. In case of remote installation, make sure you can authenticate yourself against MiCADO master. We recommend to deploy your public ssh key on MiCADO master before starting the deployment
* **ansible_user**: specifies the name of your sudoer account, defaults to "ubuntu"
* **ansible_become**: specifies if account change is needed to become root, defaults to "True"
* **ansible_become_method**: specifies which command to use to become superuser, defaults to "sudo"
* **ansible_python_interpreter**: specifies the interpreter to be used for ansible on the target host, defaults to "/usr/bin/python3"

Please, revise all the parameters, however in most cases the default values are correct.

Step 6: Start the installation of MiCADO master.
------------------------------------------------


Run the following command to build and initalise a MiCADO master node on the empty VM you launched in Step 4 and pointed to in Step 5.
::

   ansible-playbook -i hosts micado-master.yml

If you have used Vault to encrypt your credentials, you have to add the path to your vault credentials to the command line as described in the `Ansible Vault documentation <https://docs.ansible.com/ansible/2.4/vault.html#providing-vault-passwords>`_ or provide it via command line using the command
::

    ansible-playbook -i hosts micado-master.yml --ask-vault-pass


(Optional)
**********
You can now split the deployment of your MiCADO Master in two. The ``build`` tags prepare the node will all the necessary dependencies, libraries and images necessary for operation. The ``start`` tags intialise the cluster and all the MiCADO core components.

You can clone the drive of a **"built"** MiCADO Master (or otherwise make an image from it) to be reused again and again. This will greatly speed up the deployment of future instances of MiCADO.

Running the following command will ``build`` a MiCADO Master node on an empty Ubuntu 16.04 VM.
::

   ansible-playbook -i hosts micado-master.yml --tags 'build'

You can then run the following command to ``start`` any **"built"** MiCADO Master node which will initialise and launch the core components for operation.
::

   ansible-playbook -i hosts micado-master.yml --tags 'start'

As a last measure of increasing efficiency, you can now also ``build`` a MiCADO Worker node. You can then clone/snapshot/image the drive of this VM and point to it in your ADT descriptions. Before running this operation, you must adjust the *hosts* file accordingly, as you did in Step 4, this time changing the values on the line beginning **micado-worker**. The following command will ``build`` a MiCADO Worker node on an empty Ubuntu 16.04 VM.
::

   ansible-playbook -i hosts build-micado-worker.yml


After deployment
================

Once the deployment has successfully finished, you can proceed with

* visiting the :ref:`dashboard`
* using the :ref:`restapi`
* playing with the :ref:`tutorials`
* creating your :ref:`applicationdescription`

Check the logs
==============

All logs are now available via the Kubernetes Dashboard on the MiCADO Dashboard. You can navigate to them by changing the **namespace** to ``micado-system`` or ``micado-worker`` and then accessing the logs in the **Pods** section
You can also SSH into MiCADO master and check the logs at any point after MiCADO is succesfully deployed. All logs are kept under ``/var/log/micado`` and are organised by components. Scaling decisions, for example, can be inspected under ``/var/log/micado/policykeeper``

Accessing user-defined service
==============================

In case your application contains a container exposing a service, you will have to ensure the following to access it.

* First set **nodePort: xxxxx** (where xxxxx is a port in range 30000-32767) in the **properties: ports:** TOSCA description of your docker container. More information on this in the :ref:`applicationdescription`
* The container will be accessible at *<IP>:<port>* . Both, the IP and the port values can be extracted from the Kubernetes Dashboard (in case you forget it). The **IP** can be found under *Nodes > my_micado_vm > Addresses* menu, while the **port** can be found under *Discovery and load balancing > Services > my_app > Internal endpoints* menu.

