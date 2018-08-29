Deployment
**********

As stated in the above section, to use MiCADO, you need to deploy the MiCADO services on a (separate) virtual machine, called MiCADO master. We recommend doing the installation remotely i.e. to download the Ansible playbook on your local machine and run the deployment on an empty virtual machine dedicated for this purpose on your preferred cloud.

Prerequisites
=============

Git & Ansible 2.4 or greater are needed on your (local) machine to run the Ansible playbook.

**The version of Ansible in the Ubuntu 16.04 APT repository is outdated and insufficient**

Ansible
-------

Install Ansible on Ubuntu 16.04.
::

   sudo apt-get update
   sudo apt-get install software-properties-common
   sudo apt-add-repository ppa:ansible/ansible
   sudo apt-get update
   sudo apt-get install ansible

To install Ansible on other operation system follow the `official
installation
guide <#https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html>`__.

Installation
============

Perform the following steps on your local machine.

Step 1: Download the ansible playbook.
--------------------------------------

Currently, MiCADO v5 version is available.

::

   git clone https://github.com/micado-scale/ansible-micado.git ansible-micado
   cd ansible-micado
   git checkout master

Step 2: Specify credential for instantiating MiCADO workers.
------------------------------------------------------------

MiCADO master will use this credential to start/stop VM instances (MiCADO workers) to realize scaling. Credentials here should belong to the same cloud as where MiCADO master is running. We recommend making a copy of our predefined template and edit it. The ansible playbook expects the credential in a file, called credentials.yml. Please, do not modify the structure of the template!

::

   cp sample-credentials.yml credentials.yml
   vi credentials.yml

Edit credentials.yml to add cloud credentials. You will find predefined sections in the template for each cloud interface type MiCADO supports. Fill only the section belonging to your target cloud.

Step 3: (Optional) Specify details of your private Docker repository.
---------------------------------------------------------------------

Set the Docker login credentials of your private Docker registries in which your personal containers are stored. We recommend making a copy of our predefined template and edit it. The ansible playbook expects the docker registry details in a file, called docker-cred.yml. Please, do not modify the structure of the template!

::

   cp sample-docker-cred.yml docker-cred.yml
   vi docker-cred.yml

Edit docker-cred.yml and add username, password, and repository url. To login to the default docker_hub, leave DOCKER_REPO as is (a blank string).

Step 4: Launch an empty cloud VM instance for MiCADO master.
------------------------------------------------------------

This new VM will host the MiCADO master core services. Use any of aws, ec2, nova, etc command-line tools or web interface of your target cloud to launch a new VM. We recommend a VM with 2 cores, 4GB RAM, 20GB disk. Make sure you can ssh to it (password-free i.e. ssh public key is deployed) and your user is able to sudo (to install MiCADO as root). Store its IP address which will be referred as ``IP`` in the following steps. The following ports should be open on the virtual machine:

::

   TCP: 22,2377,3000,4000,5000,5050,7946,8080,8300,8301,8302,8500,8600,9090,9093,12345
   UDP: 4789,7946,8301,8302,8600

Step 5: Customize the inventory file for the MiCADO master.
-----------------------------------------------------------

We recommend making a copy of our predefined template and edit it. Use the template inventory file, called sample-hosts for customisation.

::

   cp sample-hosts hosts
   vi hosts

Edit the ``hosts`` file to set ansible variables for MiCADO master machine. Update the following parameters: ansible_host=\ *IP*, ansible_connection=\ *ssh* and ansible_user=\ *YOUR SUDOER ACCOUNT*. Please, revise the other parameters as well, however in most cases the default values are correct.

Step 6: Start the installation of MiCADO master.
------------------------------------------------

::

   ansible-playbook -i hosts micado-master.yml

Health checking
===============

At the end of the deployment, core MiCADO services will be running on the MiCADO master machine. Here are the commands to test the operation of some of the core MiCADO services:

*  Occopus:
::

    curl -s -X GET http://IP:5000/infrastructures/
*  Prometheus:
::

    curl -s http://IP:9090/api/v1/status/config | jq '.status'

Check the logs
==============

Alternatively, you can SSH into MiCADO master and check the logs at any point after MiCADO is succesfully deployed. All logs are kept under ``/var/log/micado`` and are organised by component. Scaling decisions, for example, can be inspected under ``/var/log/micado/policykeeper``