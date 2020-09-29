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
* ansible==2.9.12

Get the MiCADO Client Library
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Currently, the library is available directly from github.

Simply clone the respository and add the location to your PYTHONPATH

.. code-block:: console

  $ MCPATH="/usr/local/lib/micado-client"
  $ git clone https://github.com/micado-scale/micado-client $MC_PATH
  $ export PYTHONPATH="${PYTHONPATH}:$MC_PATH"

Specify cloud credentials
~~~~~~~~~~~~~~~~~~~~~~~~~
Specify cloud credential for MiCADO master VM creation. This file should
be saved at ``~/.micado-cli/credentials-cloud-api.yml``

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

For more detail, see the Documentation Reference section below

**Usage with a launcher:**

.. note::
    Before you start testing, make sure the authentication data in the correct place.

.. code:: Python

    from micado import MicadoClient

    client = MicadoClient(launcher="openstack")
    client.master.create(auth_url='yourendpoint',
                         project_id='project_id',
                         image='image_name or image_id',
                         flavor='flavor_name or flavor_id',
                         network='network_name or network_id',
                         keypair='keypair_name or keypair_id',
                         security_group='security_group_name or security_group_id')
 
    client.applications.list()
    client.applications.create(app_id="hello-world",
                               url="https://example.com/repo/hw_adt.yaml")
    client.applications.get("hello-world")
    client.applications.delete("hello-world")

    client.master.destroy(id='VM ID',
                          auth_url='yourendpoint',
                          project_id='project_id')



**Usage without a launcher:**

.. code:: Python

    from micado import MicadoClient

    client = MicadoClient(endpoint="https://micado/toscasubmitter/",
                          version="v2.0",
                          verify=False,
                          auth=("ssl_user", "ssl_pass"))
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
* Handle multiple MiCADO-master VM
* Support additional Cloud interface
