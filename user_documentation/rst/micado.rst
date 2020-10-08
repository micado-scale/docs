.. _micado_client_lib:

MiCADO Client Library
*********************

Overview
--------

MiCADO client library extends the MiCADO functionality with MiCADO master deployment
capabilities and application management. The library aims to provide a basic API from
Python environment and support the following:

* Deploy MiCADO service
    - Create, Destroy MiCADO master VM
* Manage application
    - Create, Update, Delete MiCADO applications

Currently, client library supports only NOVA interface. We plan to extend with additional
interfaces later.

Getting Started
---------------

Install requirements
~~~~~~~~~~~~~~~~~~~~
The required Python packages are defined under the ``requirements.txt``. Make sure to
install those before using MiCADO client library. For reference, they are:

* requests==2.24.0
* ruamel.yaml==0.16.10
* pycryptodome==3.9.8
* python-novaclient==17.2.0
* openstacksdk==0.48.0
* ansible==2.10.0

Get the MiCADO Client Library
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Currently, the library is available directly from github.

Simply clone the respository and add the location to your PYTHONPATH

.. code-block:: console

  $ MC_PATH="/usr/local/lib/micado-client"
  $ git clone https://github.com/micado-scale/micado-client $MC_PATH
  $ export PYTHONPATH="$PYTHONPATH:$MC_PATH"
  $ mkdir -p ~/.micado-cli
  $ touch ~/.micado-cli/credentials-cloud-api.yml

Specify cloud credentials
~~~~~~~~~~~~~~~~~~~~~~~~~
Specify cloud credential for MiCADO master VM creation. Please,
edit ``~/.micado-cli/credentials-cloud-api.yml``

.. code:: yaml

    resource:
    -
        type: nova
        auth_data:
            # Select your authentication method
            # Option #1
            username:
            password:
            # Option #2
            application_credential_id:
            application_credential_secret:


Example
-------

.. note::
    Before you start testing, make sure the authentication data in the correct place.

For more details, see the Documentation Reference section below.
There are three use-cases identified for using micado-client.

**Use-case 1**

MiCADO master is created with the help of MiCADO client library. The create and destroy methods
are invoked in the same program i.e. storing and retrieving the ``client.master`` object is not needed.

.. code:: Python

    from micado import MicadoClient

    client = MicadoClient(launcher="openstack")
    client.master.create(
        auth_url='yourendpoint',
        project_id='project_id',
        image='image_name or image_id',
        flavor='flavor_name or flavor_id',
        network='network_name or network_id',
        keypair='keypair_name or keypair_id',
        security_group='security_group_name or security_group_id'
        )
    client.applications.list()
    client.master.destroy()

**Use-case 2**

MiCADO master is created with the help of MiCADO client library. The create and destroy methods
are invoked in seperate programs i.e. storing and retrieving the ``client.master`` object is needed.

    .. code:: Python

        from micado import MicadoClient

        client = MicadoClient(launcher="openstack")
        master_id = client.master.create(
            auth_url='yourendpoint',
            project_id='project_id',
            image='image_name or image_id',
            flavor='flavor_name or flavor_id',
            network='network_name or network_id',
            keypair='keypair_name or keypair_id',
            security_group='security_group_name or security_group_id'
            )
        client.applications.list()
        << store your master_id >>
        << exiting... >>
        -------------------------------------------------------------
        << start >>
        ...
        master_id = << retrieve master_id >>
        client = MicadoClient(launcher="openstack")
        client.master.attach(master_id = master_id)
        client.applications.list()
        client.master.destroy()

**Use-case 3**

MiCADO master is created independently from the MiCADO client library. The create and destroy methods
are not invoked since the client library used only for handling the applications.

    .. code:: Python

        from micado import MicadoClient
        client = MicadoClient(
            endpoint="https://micado/toscasubmitter/",
            version="v2.0",
            verify=False,
            auth=("ssl_user", "ssl_pass")
            )
        client.applications.list()

Documentation Reference
-----------------------

.. toctree::
   :maxdepth: 4

   micado.client
   micado.models.application
   micado.models.master

Roadmap
-------
* Support additional Cloud interface (e.g EC2)
