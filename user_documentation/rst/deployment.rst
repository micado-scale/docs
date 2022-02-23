.. _deployment:

Deployment
**********

To deploy MiCADO you need a (separate) virtual machine, called MiCADO master. There are two ways of deployment:

* remote: download the Ansible playbook on your local machine, configure the MiCADO master as target machine and run the playbook to perform the deployment remotely.
* local: login to the MiCADO master, download the Ansible playbook, configure the localhost as target machine and run the playbook to perform the deployment locally.

We recommend to perform the installation remotely as all your configuration files are preserved on your machine, i.e. it is easier to repeat the deployment if needed.

Prerequisites
=============

**A cloud interface supported by MiCADO**

* EC2 (tested on Amazon and OpenNebula)
* Nova (tested on OpenStack)
* Azure (tested on Microsoft Azure)
* GCE (tested on Google Cloud)
* CloudSigma
* CloudBroker

**MiCADO master (a virtual machine on a supported cloud)**

* Ubuntu 18.04 or 20.04
* (Minimum) 2GHz CPU & 3GB RAM & 15GB DISK
* (Recommended) 2GHz CPU & 4GB RAM & 20GB DISK

| **Ansible Remote (the host where the Ansible Playbook is executed)**
| *this could be the MiCADO Master itself, for a "local" execution of the playbook*

* Ansible 2.10 or greater
* curl
* jq (to pretty-format API responses)
* wrk (to load test nginx & wordpress demonstrators)

Ansible
-------

Note: At the time of writing, Ansible in the APT repository is either
outdated (Ubuntu 18.04) or buggy (Ubuntu 20.04).

To install Ansible on Ubuntu, we we prefer using the ``pip`` installation
method to ensure the latest release:

::

   sudo apt-get update
   sudo apt-get install python3-pip
   sudo pip3 install ansible

To install Ansible without `pip`, follow the `official installation guide <https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html>`__.

curl
----

To install curl on Ubuntu, use this command:

::

   sudo apt-get install curl

To install curl on other operating systems follow the `official installation guide <https://curl.haxx.se/download.html>`__.

jq
--

To install jq on Ubuntu, use this command:

::

   sudo apt-get install jq

To install jq on other operating systems follow the `official installation guide <https://stedolan.github.io/jq/download/>`__.

wrk (optional)
--------------

`wrk` is used to generate HTTP load for testing certain applications in MiCADO.

To install wrk, check the sidebar on the `github wiki <https://github.com/wg/wrk/wiki>`__.

Installation
============

Perform the following steps either on your local machine or on MiCADO master depending on the installation method.

Step 1: Download the ansible playbook.
--------------------------------------

::

   curl --output ansible-micado-v0.10.tar.gz -L https://github.com/micado-scale/ansible-micado/tarball/v0.10
   tar -zxvf ansible-micado-v0.10.tar.gz
   cd ansible-micado-v0.10/

.. _cloud-credentials:

Step 2: Specify cloud credential for instantiating MiCADO workers.
------------------------------------------------------------------

MiCADO master will use the credentials against the cloud API to start/stop VM
instances (MiCADO workers) to host the application and to realize scaling.
Credentials here should belong to the same cloud as where MiCADO master
is running. We recommend making a copy of our predefined template and edit it.
MiCADO expects the credential in a file, called *credentials-cloud-api.yml*
before deployment. Please, do not modify the structure of the template!

::

   cp credentials/sample-credentials-cloud-api.yml credentials/credentials-cloud-api.yml
   edit credentials/credentials-cloud-api.yml


Edit **credentials-cloud-api.yml** to add cloud credentials. You will find
predefined sections in the template for each cloud interface type MiCADO
supports. It is recommended to fill only the section belonging to your
target cloud.

**NOTE** If you are using Google Cloud, you must replace or fill the
*credentials-gce.json* with your downloaded service account key file.

::

   cp credentials/sample-credentials-gce.json credentials/credentials-gce.json
   edit credentials/credentials-gce.json

It is possible to modify cloud credentials after MiCADO has been deployed,
see the section titled **Update Cloud Credentials** further down this page

Optional: Added security
~~~~~~~~~~~~~~~~~~~~~~~~

   Credentials are stored in Kubernetes Secrets on the MiCADO Master. If
   you wish to keep the credential data in an secure format on the Ansible
   Remote as well, you can use the `Ansible Vault <https://docs.ansible.com/ansible/2.4/vault.html>`_
   mechanism to to achieve this. Simply create the above file using Vault with the
   following command

   ::

      ansible-vault create credentials/credentials-cloud-api.yml


   This will launch the editor defined in the ``$EDITOR`` environment variable to make changes to
   the file. If you wish to make any changes to the previously encrypted file, you can use the command

   ::

      ansible-vault edit credentials/credentials-cloud-api.yml

   Be sure to see the note about deploying a playbook with vault encrypted files
   in **Step 7**.

Step 3a: Specify security settings and credentials to access MiCADO.
--------------------------------------------------------------------

MiCADO master will use these security-related settings and credentials to authenticate its users for accessing the REST API and Dashboard.

::

   cp credentials/sample-credentials-micado.yml credentials/credentials-micado.yml
   edit credentials/credentials-micado.yml

Specify the provisioning method for the x509 keypair used for TLS encryption of the management interface in the ``tls`` subtree:

* The **self-signed** option generates a new keypair with the specified
  hostname as the subject / CN ('micado-master' by default, but configurable in
  **micado-master.yml**).
  
  Two Subject Alternative Name (SAN) entries are also
  added by the configuration file at
  ``roles/micado_master/start/templates/zorp/san.cnf``:
  
    - DNS: *<specified hostname>*
    - IP: *<specified IP>*

  The generated certificate file is located at:
  ``/var/lib/micado/zorp/config/ssl.pem``


* The **user-supplied** option lets the user add the keypair as plain multiline strings (in unencrypted format) in the ansible_user_data.yml file under the 'cert' and 'key' subkeys respectively.

Specify the default username and password for the administrative user in the ``authentication`` subtree.

Optionally you may use the Ansible Vault mechanism as described in Step 2 to protect the confidentiality and integrity of this file as well.


Step 3b: (Optional) Specify credentials to use private Docker registries.
-------------------------------------------------------------------------

Set the Docker login credentials of your private Docker registry in which your private containers are stored. We recommend making a copy of our predefined template and edit it. MiCADO expects the docker registry credentials in a file, called credentials-docker-registry.yml. Please, do not modify the structure of the template!

::

   cp credentials/sample-credentials-docker-registry.yml credentials/credentials-docker-registry.yml
   edit credentials/credentials-docker-registry.yml

Edit credentials-docker-registry.yml and add username, password, and registry url. To login to the default docker_hub, leave DOCKER_REPO as is (https://index.docker.io/v1/).

Optionally you may use the Ansible Vault mechanism as described in Step 2 to protect the confidentiality and integrity of this file as well.

Advanced: Multiple Registries or Token Auth
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   To login to multiple different Docker Registries, or to
   use a token for login, it is necessary to SSH to the
   MiCADO Master node **after** MiCADO has been fully deployed
   (i.e. after Step 7). You should **not** perform Step 3b above.
   
   Once logged into the MiCADO Master, use the docker login
   command as needed to login to different registries. eg.

   ::

      sudo docker login -u <username> -p <password>
      sudo docker login registry.gitlab.com -u <username> -p <token>
      ...

   This will create a config.json file, usually at
   ``~/.docker/config.json``. With the path to this file in mind,
   run the following command

   ::

      sudo kubectl create secret generic dockerloginkey \
          --from-file=.dockerconfigjson=path/to/.docker/config.json \
          --type=kubernetes.io/dockerconfigjson

   Finally, run the following command.

   ::

      sudo kubectl patch serviceaccount default \
          --patch '{"imagePullSecrets": [{"name": "dockerloginkey"}]}'


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
 UDP      500 & 4500     IPSec
========  =============  ====================

   **NOTE:** ``[web_listening_port]`` should match with the actual value specified in Step 4a.

   **NOTE:** MiCADO master has built-in firewall, therefore you can leave all ports open at cloud level.

   **NOTE:** On some network configurations, for example where IPSec
   protocols **ESP (50)** and **AH (51)** are blocked, important network
   packets can get dropped in Master-Worker communications. This might be
   seen as Prometheus scrapes failing with the error
   **context deadline exceeded**, or Workers failing to join the Kubernetes
   cluster. To disable the IPSec tunnel securing Master-Worker communications,
   it can be stopped by appending **ipsec stop** to **runcmd** in the default
   worker node *cloud-init #cloud-config*.

**c)** Finally, launch the virtual machine with the proper settings (capacity, ssh keys, firewall): use any of aws, ec2, nova, etc command-line tools or web interface of your target cloud to launch a new VM. We recommend a VM with 2 cores, 4GB RAM, 20GB disk. Make sure you can ssh to it (password-free i.e. ssh public key is deployed) and your user is able to sudo (to install MiCADO as root). Store its IP address which will be referred as ``IP`` in the following steps.

Step 5: Customize the inventory file for the MiCADO master.
-----------------------------------------------------------

We recommend making a copy of our predefined template and edit it. Use the template inventory file, called sample-hosts.yml for customisation.

::

   cp sample-hosts.yml hosts.yml
   edit hosts.yml

Edit the ``hosts.yml`` file to set the variables. The following parameters under the key **micado-target** can be updated:

* **ansible_host**: specifies the publicly reachable ip address of the target machine where you intend to build/deploy a MiCADO Master or build a MiCADO Worker. Set the public or floating ``IP`` of the master regardless the deployment method is remote or local. The ip specified here is used by the Dashboard for webpage redirection as well
* **ansible_connection**: specifies how the target host can be reached. Use "ssh" for remote or "local" for local installation. In case of remote installation, make sure you can authenticate yourself against MiCADO master. We recommend to deploy your public ssh key on MiCADO master before starting the deployment
* **ansible_user**: specifies the name of your sudoer account, defaults to "ubuntu"
* **ansible_become**: specifies if account change is needed to become root, defaults to "True"
* **ansible_become_method**: specifies which command to use to become superuser, defaults to "sudo"
* **ansible_python_interpreter**: specifies the interpreter to be used for ansible on the target host, defaults to "/usr/bin/python3"

Please, revise all the parameters, however in most cases the default values are correct.

.. _customize:

Step 6: Customize the deployment
--------------------------------

A few parameters in *group_vars/micado.yml* can be fine tuned before deployment. They are as follows:

- **enable_optimizer**: Setting this parameter to True enables the deployment of the Optimizer module, to perform more advanced scaling. Default is True.

- **disable_worker_updates**: Setting this parameter to False enables periodic software updates of the worker nodes. Default is True.

- **grafana_admin_pwd**: The string defined here will be the password for Grafana administrator.

- **web_listening_port**: Port number of the dasboard on MiCADO master. Default is 443.

- **web_session_timeout**: Timeout value in seconds for the Dashboard. Default is 600.

- **enable_occopus**: Install and enable Occopus for cloud orchestration. Default is True.

- **enable_terraform**: Install and enable Terraform for cloud orchestration. Default is False.

*Note. MiCADO supports running both Occopus & Terraform on the same Master, if desired*

Step 7: Start the installation of MiCADO master.
------------------------------------------------

Run the following command to build and initalise a MiCADO master node on the empty VM you launched in Step 4 and pointed to in *hosts.yml* Step 5.

::

   ansible-playbook -i hosts.yml micado.yml

If you have used Vault to encrypt your credentials, you have to add the path to your vault credentials to the command line as described in the `Ansible Vault documentation <https://docs.ansible.com/ansible/2.4/vault.html#providing-vault-passwords>`_ or provide it via command line using the command

::

   ansible-playbook -i hosts.yml micado.yml --ask-vault-pass

Optional: Build & Start Roles
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   Optionally, you can split the deployment of your MiCADO Master in two. The ``build`` tags prepare the node will all the necessary dependencies, libraries and images necessary for operation. The ``start`` tags intialise the cluster and all the MiCADO core components.

   You can clone the drive of a **"built"** MiCADO Master (or otherwise make an image from it) to be reused again and again. This will greatly speed up the deployment of future instances of MiCADO.

   Running the following command will ``build`` a MiCADO Master node on an empty Ubuntu VM.

   ::

      ansible-playbook -i hosts.yml micado.yml --tags build

   You can then run the following command to ``start`` any **"built"** MiCADO Master node which will initialise and launch the core components for operation.

   ::

      ansible-playbook -i hosts.yml micado.yml --tags start

   As a last measure of increasing efficiency, you can also ``build`` a MiCADO Worker node. You can then clone/snapshot/image the drive of this VM and point to it in your ADT descriptions. Before running this operation, Make sure the *hosts.yml* points to the empty VM where you intend to build the worker image. Adjust the values under the key **micado-target** as needed. The following command will ``build`` a MiCADO Worker node on an empty Ubuntu VM.

   ::

      ansible-playbook -i hosts.yml worker.yml


Advanced: Cloud specific fixes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   Certain cloud service providers may provide Virtual Machine images that are
   incompatible with the normal MiCADO installation. Where possible, we have included
   automated fixes for these, which can be applied using the `--tags` syntax of Ansible.
   See below for details:

   **CloudSigma**

   At the time of writing, the CloudSigma Ubuntu 18.04 and 20.04 virtual machine disk images
   are improperly configured, and SSL errors may appear during installation of MiCADO. A special
   task has been added to MiCADO to automate the fix when installing on CloudSigma instances.

   Simply use the following command instead of the command provided above. Notice the added tags

   ::

      ansible-playbook -i hosts.yml micado.yml --tags all,cloudsigma


After deployment
================

Once the deployment has successfully finished, you can proceed with

* visiting the :ref:`dashboard`
* using the :ref:`restapi`
* playing with the :ref:`tutorials`
* creating your :ref:`applicationdescription`


Update Cloud Credentials
========================

It is possible to modify cloud credentials on an already deployed MiCADO
Master. Simply make the necessary changes to the appropriate credentials
file (using *ansible-vault* if desired) and then run the following playbook
command:

::

   ansible-playbook -i hosts.yml micado.yml --tags update-auth


Check the logs
==============

All logs are now available via the Kubernetes Dashboard on the MiCADO Dashboard. You can navigate to them by changing the **namespace** to ``micado-system`` or ``micado-worker`` and then accessing the logs in the **Pods** section
You can also SSH into MiCADO master and check the logs at any point after MiCADO is succesfully deployed. All logs are kept under ``/var/log/micado`` and are organised by components. Scaling decisions, for example, can be inspected under ``/var/log/micado/policykeeper``

Accessing user-defined service
==============================

In case your application contains a container exposing a service, you will have to ensure the following to access it.

* First set **nodePort: xxxxx** (where xxxxx is a port in range 30000-32767) in the **properties: ports:** TOSCA description of your docker container. More information on this in the :ref:`applicationdescription`
* The container will be accessible at *<IP>:<port>* . Both, the IP and the port values can be extracted from the Kubernetes Dashboard (in case you forget it). The **IP** can be found under *Nodes > my_micado_vm > Addresses* menu, while the **port** can be found under *Discovery and load balancing > Services > my_app > Internal endpoints* menu.
