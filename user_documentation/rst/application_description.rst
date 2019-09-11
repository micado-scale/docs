.. _applicationdescription:


Application Description Templates (ADT)
=======================================

Overview
--------

MiCADO executes applications described by an Application Description Template.
ADTs follow the `TOSCA Specification
<http://docs.oasis-open.org/tosca/TOSCA-Simple-Profile-YAML/v1.2/TOSCA-Simple-Profile-YAML-v1.2.pdf>`_
and are described in detail in this section.

The three main sections of an ADT
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Top-level definitions**

* **tosca_definitions_version**: ``tosca_simple_yaml_1_0``.
* **imports**: List of urls pointing to custom TOSCA types.
  The default url points to the custom types defined for MiCADO.
  Please, do not modify this url.
* **repositories**: Docker repositories with their addresses.

**Topology template section**

* **node_templates:** Definitions of the application containers (see
  **Specification of the Application**) and auxilary
  components such as a volume (see **Specification of Volumes**)
  and virtual machines (see **Specification of the Virtual Machine**)
* **policies:** Scaling & metric policies (see **Specification of Policies**)

**Types section (optional)**

  This section is used to optionally define additional detailed types which
  can be referenced in the **topology_template** section to benefit from
  abstraction. Under **policy_types:** for example, complex scaling logic
  can be defined here, then referenced in the **policies** section above


Example of the overall structure of an ADT
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

::

   tosca_definitions_version: tosca_simple_yaml_1_0

   imports:
     - https://raw.githubusercontent.com/micado-scale/tosca/v0.8.0/micado_types.yaml

   repositories:
     docker_hub: https://hub.docker.com/
     custom_registry: https://my-registry.mydomain.eu/

   topology_template:
     node_templates:
       YOUR-KUBERNETES-APP:
         type: tosca.nodes.MiCADO.Container.Application.Docker
         properties:
           ...
         artifacts:
           ...
         interfaces:
           ...
         requirements:
           ...
       
       YOUR-VOLUME:
         type: tosca.nodes.MiCADO.Container.Volume
         properties:
           ...
         interfaces:
           ...

       YOUR-VIRTUAL-MACHINE:
         type: tosca.nodes.MiCADO.<CLOUD_API_TYPE>.Compute
         properties:
           ...
         interfaces:
           ...
         capabilities:
           ...

     policies:
     - scalability:
       type: tosca.policies.Scaling.MiCADO
       targets: [ YOUR-VIRTUAL-MACHINE ]
       properties:
         ...
     - scalability:
       type: tosca.policies.Scaling.MiCADO
       targets: [ YOUR-KUBERNETES-APP ]
       properties:
         ...
     - scalability:
       type: tosca.policies.Scaling.MiCADO
       targets: [ YOUR-OTHER-KUBERNETES-APP ]
       properties:
         ...

Specification of the Application
--------------------------------

Under the node_templates section you can define one or more Docker containers
and choose to orchestrate them with Kubernetes (see **YOUR-KUBERNETES-APP**).
Each container is described as a separate named node which references a
**type** (more on types below). The definition of the most basic container
consists of the following:

**NOTE** Kubernetes does not allow for underscores in any resource names
(ie TOSCA node names). Names must also begin and end with an alphanumeric.

Properties
~~~~~~~~~~
The fields under the **properties** section of the Kubernetes app are a
collection of options specific to all iterations of Docker containers.
The translator understands both Docker-Compose style naming and Kubernetes
style naming, though the Kubernetes style is recommended. You can find
additional information about properties in the `translator documentation
<https://github.com/jaydesl/TOSCAKubed/blob/master/README.md>`__. These
properties will be translated into Kubernetes manifests on deployment.

Under the **properties** section of an app (see **YOUR-KUBERNETES-APP**)
here are a few common keywords:

* **name**: name for the container (defaults to the TOSCA node name)
* **command**: override the default command line of the container (*list*)
* **args**: override the default entrypoint of container (*list*)
* **env**: list of required environment variables in format:

  * **name:**
  * **value:**
* **resource:**

  * **requests:**
  
    * **cpu**: CPU reservation, core components usually require 100m so assume
      900m as a maximum
* **ports**: list of published ports to the host machine, you can specify these
  keywords in the style of a flattened (*Service*, *ServiceSpec* and
  *ServicePort* can all be defined at the same level - `see Kubernetes Service
  <https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.15/#service-v1-core>`__)

  * **targetPort**: the port to target (assumes port if not specified)
  * **port**: the port to publish (assumes targetPort if not specified)
  * **name**: the name of this port in the service (generated if not specified)
  * **protocol**: the protocol for the port (defaults to: TCP)
  * **nodePort**: the port (30000-32767) to expose on the host
    (will create a nodePort Service unless type is explicitly set below)
  * **type**: the type of service for this port (defaults to: ClusterIP
    unless nodePort is defined above)
  * **clusterIP**: the desired (internal) IP (10.0.0.0/24) for this service
    (defaults to next available)
  * **metadata**: service metadata, giving the option to set a name for the
    service. Explicit naming can be used to group different ports together
    (default grouping is by type)

Artifacts
~~~~~~~~~
Under the **artifacts** section you can define the docker image for the
kubernetes app. Three fields must be defined:

* **type**: ``tosca.artifacts.Deployment.Image.Container.Docker``
* **file**: docker image for the kubernetes app
  (e.g. sztakilpds/cqueue_frontend:latest )
* **repository**: name of the repository where the image is located.
  The name used here (e.g. docker_hub), must be defined at the top of
  the description under the **repositories** section.

Requirements
~~~~~~~~~~~~
Under the **requirements** section you can define the virtual machine
you want to host this particular app, restricting the container to run
**only** on that VM. If you do not provide a host requirement, the container
will run on any possible virtual machine. You can also attach a volume to
this app - the definition of volumes can be found in the next section.
Requirements takes a list of map objects:

* **host:** name of your virtual machine as defined under node_templates
* **volume:**

  * **node:** name of your volume as defined under node_templates
  * **relationship:** **!!**

    * **type:** ``tosca.relationships.AttachesTo``
    * **properties:**

      * **location:** path on container

* **container:** name of a sidecar container defined as a
  ``tosca.nodes.MiCADO.Container.Application.Docker`` type under
  node_templates. The sidecar will share the Kubernetes Pod with
  the main container (the sidecar should not be given an interface)
  **(NEW in v0.8.0)**

**!! (NEW in v0.8.0)** If a relationship is not defined for a volume the
path on container will be the same as the path defined in the volume
(see Specification of Volumes)

Interfaces
~~~~~~~~~~
Under the **interfaces** section you can define orchestrator specific
options, to instruct MiCADO to use Kubernetes, we use the key **Kubernetes**.
Fields under **inputs:** will be translated directly to a Kubernetes manifest
so it is possible to use the full range of properties which Kubernetes offers
as long as field names and syntax follow `the Kubernetes documentation <https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.15/#deployment-v1-apps>`__
If **inputs:** is omitted a set of defaults will be used to create a Deployment

* **create**: *this key tells MiCADO to create a workload*
  *(Deployment/DaemonSet/Job/Pod etc...) for this container*

  * **inputs**: *top-level workload and workload spec options go here...
    two examples, for more see* `translator documentation <https://github.com/jaydesl/TOSCAKubed/blob/master/README.md>`__

    * **kind:** overwrite the workload type (defaults to Deployment)
    * **spec:**

      * **strategy:**

        * **type:** Recreate (kill pods then update instead of RollingUpdate)

* **configure**: *this key configures the Pod for this workload*

  * **inputs**: `PodTemplateSpec <https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.13/#podspec-v1-core>`__ options follow here... For example

    * **spec:**

      * **restartPolicy:** change the restart policy (defaults to Always)

Types
~~~~~

**NEW in v0.8.0** Through abstraction, it is possible to reference a
pre-defined type and simplify the description of a container. Currently
MiCADO supports these types, though more can be written:

* **tosca.nodes.MiCADO.Container.Application.Docker** -
  The base and most common type for Docker containers in MiCADO. If the
  desired Docker container image is stored in DockerHub, the property
  **image:** can be used instead of defining **artifacts:**

* **tosca.nodes.MiCADO.Container.Application.Docker.Deployment** -
  As above, but orchestrated as a Kubernetes Deployment so that **interfaces:**
  is not required

* **tosca.nodes.MiCADO.Container.Application.Docker.DaemonSet** -
  As above, but for a Kubernetes DaemonSet

* **tosca.nodes.MiCADO.Container.Pod.Kubernetes** -
  Creates an empty Pod. No properties are available, so to use this type
  a container must be defined and **assigned no interface** as type
  ``tosca.nodes.MiCADO.Container.Application.Docker`` and referenced under
  **requirements:** (more than one container can be referenced to run
  multiple containers in a single Pod)

* **tosca.nodes.MiCADO.Container.Pod.Kubernetes.Deployment** -
  As above, but a Kubernetes Deployment

Examples of the definition of a basic application
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**With** *tosca.nodes.MiCADO.Container.Application.Docker* **and the**
**Docker image in a custom repository**
::

  YOUR-KUBERNETES-APP:
    type: tosca.nodes.MiCADO.Container.Application.Docker
    properties:
      name:
      command:
      args:
      env:
      ...
    artifacts:
      image:
        type: tosca.artifacts.Deployment.Image.Container.Docker
        file: YOUR_DOCKER_IMAGE
        repository: custom_registry
    requirements:
    - host: YOUR-VIRTUAL-MACHINE
    interfaces:
      Kubernetes:
        create:
          inputs:
          ...

**With** *tosca.nodes.MiCADO.Container.Application.Docker* **and the**
**Docker image in DockerHub**
::

  YOUR-KUBERNETES-APP:
    type: tosca.nodes.MiCADO.Container.Application.Docker
    properties:
      image: YOUR_DOCKER_IMAGE
      name:
      command:
      args:
      env:
      ...
    requirements:
    - host: YOUR-VIRTUAL-MACHINE
    interfaces:
      Kubernetes:
        create:
          inputs:
          ...

**With** *tosca.nodes.MiCADO.Container.Application.Docker.Deployment*
**and the Docker image in DockerHub**
::

  YOUR-KUBERNETES-APP:
    type: tosca.nodes.MiCADO.Container.Application.Docker.Deployment
    properties:
      image: YOUR_DOCKER_IMAGE
      name:
      command:
      args:
      env:
      ...
    requirements:
    - host: YOUR-VIRTUAL-MACHINE

**Multiple containers in a single Pod, images in DockerHub**
::

  YOUR-KUBERNETES-APP:
    type: tosca.nodes.MiCADO.Container.Application.Docker
    properties:
      image: YOUR_DOCKER_IMAGE
      name:
      command:
      ...

  YOUR-OTHER-KUBERNETES-APP:
    type: tosca.nodes.MiCADO.Container.Application.Docker
    properties:
      image: YOUR_OTHER_DOCKER_IMAGE
      name:
      command:
      ...

  YOUR-KUBERNETES-POD:
    type: tosca.nodes.MiCADO.Container.Pod.Kubernetes
    requirements:
    - container: YOUR-KUBERNETES-APP
    - container: YOUR-OTHER-KUBERNETES-APP

Networking in Kubernetes
~~~~~~~~~~~~~~~~~~~~~~~~

Kubernetes networking is inherently different to the approach taken by
Docker/Swarm. This is a complex subject which is worth a `read here <https://kubernetes.io/docs/concepts/cluster-administration/networking/>`__
. Since every pod gets its own IP, which any pod can by default use to
communicate with any other pod, this means there is no network to
explicitly define. If the **ports** keyword is defined in the definition
above, pods can reach each other over CoreDNS via their hostname (container
name).

Under the **outputs** section (this key is nested within *topology_template*)
you can define an output to retrieve from Kubernetes via the adaptor.
Currently, only port info is obtainable.

::

  outputs:
    ports:
      value: { get_attribute: [ YOUR-KUBERNETES-APP, port ]}

Specification of Volumes
------------------------
Volumes are defined at the same level as virtual machines and containers,
and are then connected to containers using the **requirements:** notation
discussed above in the container spec. Some examples of attaching volumes
will follow.

Interfaces
~~~~~~~~~~
Under the **interfaces** section you should define orchestrator specific
options, here we again use the key **Kubernetes:**

* **create**: *this key tells MiCADO to create a persistent volume and claim*

  * **inputs**: persistent volume specific spec options... here are two
    popular examples, see `Kubernetes volumes <https://kubernetes.io/docs/concepts/storage/volumes/>`__ for more

    * **nfs:**

      * **server:** IP of NFS server
      * **path:** path on NFS share

    * **hostPath:**

      * **path:** path on host

* **configure**: 

  * **inputs**: using this key, options can be overwritten in the claim

Types
~~~~~

**NEW in v0.8.0** Through abstraction, it is possible to reference a
pre-defined type and simplify the description of a volume. Currently
MiCADO supports these types, though more can be written:

* **tosca.nodes.MiCADO.Container.Volume** -
  The base and most common type for Docker volumes in MiCADO. It is
  necessary to define further fields under **interfaces:**
* **tosca.nodes.MiCADO.Container.Volume.EmptyDir** -
  Creates a `EmptyDir <https://kubernetes.io/docs/concepts/storage/volumes/#emptydir>`__
  persistent volume and claim in Kubernetes
* **tosca.nodes.MiCADO.Container.Volume.HostPath** -
  Creates a `HostPath <https://kubernetes.io/docs/concepts/storage/volumes/#hostpath>`__
  volume. Define the path on host as **path:** under **properties:**
* **tosca.nodes.MiCADO.Container.Volume.NFS** -
  Creates an `NFS <https://kubernetes.io/docs/concepts/storage/volumes/#nfs>`__
  volume. Define the path and server IP as **path:** and **server:**
  under **properties:**
* **tosca.nodes.MiCADO.Container.Volume.GlusterFS** -
  Creates a `GlusterFS <https://kubernetes.io/docs/concepts/storage/volumes/#glusterfs>`__
  volume. Define path, endpoint and readOnly flag as **path:**, **endpoints:**,
  and **readOnly:** under **properties:**

Examples of the definition of a basic volume
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**With** *tosca.nodes.MiCADO.Container.Volume*
::

  YOUR-VOLUME:
    type: tosca.nodes.MiCADO.Container.Volume
    interfaces:
      Kubernetes:
        create:
          inputs:
            nfs:
              path: /exports
              server: 10.96.0.1


  YOUR-KUBERNETES-APP:
    type: tosca.nodes.MiCADO.Container.Application.Docker.Deployment
    properties:
      ...
    requirements:
    - volume:
        node: YOUR-VOLUME
        relationship:
          type: tosca.relationships.AttachesTo
          properties:
            location: /tmp/container/mount/point

**Another example with** *tosca.nodes.MiCADO.Container.Volume*

  Here, no **relationship** is defined under **requirements** so the path
  defined by the volume */etc/mypath* will be used as the container mount point

::

  YOUR-VOLUME:
    type: tosca.nodes.MiCADO.Container.Volume
    interfaces:
      Kubernetes:
        create:
          inputs:
            hostPath:
              path: /etc/mypath

  YOUR-KUBERNETES-APP:
    type: tosca.nodes.MiCADO.Container.Application.Docker.Deployment
    properties:
      ...
    requirements:
    - volume: YOUR-VOLUME

**With** *tosca.nodes.MiCADO.Container.Volume.EmptyDir*

::

  YOUR-VOLUME:
    type: tosca.nodes.MiCADO.Container.Volume.EmptyDir

  YOUR-KUBERNETES-APP:
    type: tosca.nodes.MiCADO.Container.Application.Docker.Deployment
    properties:
      ...
    requirements:
    - volume:
        node: YOUR-VOLUME
        relationship:
          type: tosca.relationships.AttachesTo
          properties:
            location: /tmp/container/mount/point

**With** *tosca.nodes.MiCADO.Container.Volume.NFS*

::

  YOUR-VOLUME:
    type: tosca.nodes.MiCADO.Container.Volume.NFS
    properties:
      path: /exports
      server: 10.96.0.1

  YOUR-KUBERNETES-APP:
    type: tosca.nodes.MiCADO.Container.Application.Docker.Deployment
    properties:
      ...
    requirements:
    - volume:
        node: YOUR-VOLUME
        relationship:
          type: tosca.relationships.AttachesTo
          properties:
            location: /tmp/container/mount/point

Specification of the Virtual Machine
------------------------------------

The collection of docker containers (kubernetes applications) specified in the
previous section is orchestrated by Kubernetes. This section introduces how the
parameters of the virtual machine can be configured which will host the
Kubernetes worker node. During operation MiCADO will instantiate as many
virtual machines with the parameters defined here as required during scaling.
MiCADO currently supports four different cloud interfaces: CloudSigma,
CloudBroker, EC2, Nova. MiCADO supports multiple virtual machine "sets"
which can be restricted and host only specific containers (defined in the
requirements section of the container specification). At the moment multi-cloud
support is in alpha stage, so only certain combinations of different cloud
service providers will work.

**NOTE** Underscores are not permitted in virtual machine names
(ie TOSCA node names). Names should also begin and end with an alphanumeric.

.. _workerfirewallconfig:

The following ports and protocols should be enabled on the virtual machine acting as MiCADO worker, replacing [exposed_application_ports] with ports you wish to expose on the host:

========  =============  ====================
Protocol  Port(s)        Service
========  =============  ====================
 TCP      30000-32767*   exposed application node ports (configurable*)
 TCP      22             SSH
 TCP      10250          kubelet
 UDP      8285 & 8472    flannel overlay network
========  =============  ====================

The following subsections details how to configure them.

General
~~~~~~~

The **capabilities** sections for all virtual machine definitions that follow are identical and are **ENTIRELY OPTIONAL**. They are filled with metadata to support human readability.:

*  **num_cpus** under *host* is a readable string specifying clock speed of the instance type
*  **mem_size** under *host* is a readable string specifying RAM of the instance type
*  **type** under *os* is a readable string specifying the operating system type of the image
*  **distribution** under *os* is a readable string specifying the OS distro of the image
*  **version** under *os* is a readable string specifying the OS version of the image

The **interfaces** section of all virtual machine definitions that follow are **REQUIRED**, and allow you to provide orchestrator specific inputs, in the examples below we use **Occopus**.

* **create**: *this key tells MiCADO to create the VM using Occopus*

  * **inputs**: Specific settings for Occopus follow here
  
    * **interface_cloud:** tells Occopus which cloud type to interface with
    * **endpoint_cloud:** tells Occopus the endpoint API of the cloud



CloudSigma
~~~~~~~~~~

To instantiate MiCADO workers on CloudSigma, please use the template below. MiCADO **requires** num_cpus, mem_size, vnc_password, libdrive_id, public_key_id and firewall_policy to instantiate VM on *CloudSigma*.

::

  YOUR-VIRTUAL-MACHINE:
    type: tosca.nodes.MiCADO.CloudSigma.Compute
      properties:
        num_cpus: ADD_NUM_CPUS_FREQ (e.g. 4096)
        mem_size: ADD_MEM_SIZE (e.g. 4294967296)
        vnc_password: ADD_YOUR_PW (e.g. secret)
        libdrive_id: ADD_YOUR_ID_HERE (eg. 87ce928e-e0bc-4cab-9502-514e523783e3)
        public_key_id: ADD_YOUR_ID_HERE (e.g. d7c0f1ee-40df-4029-8d95-ec35b34dae1e)
        nics:
        - firewall_policy: ADD_YOUR_FIREWALL_POLICY_ID_HERE (e.g. fd97e326-83c8-44d8-90f7-0a19110f3c9d)
          ip_v4_conf:
            conf: dhcp
      capabilities:
      # OPTIONAL METADATA
        host:
          properties:
            num_cpus: 2GHz
            mem_size: 2GB
        os:
          properties:
            type: linux
            distribution: ubuntu
            version: 16.04
      interfaces:
        Occopus:
          create:
            inputs:
              interface_cloud: cloudsigma
              endpoint_cloud: ADD_YOUR_ENDPOINT (e.g for cloudsigma https://zrh.cloudsigma.com/api/2.0 )

Under the **properties** section of a CloudSigma virtual machine definition these inputs are available.:

*  **num_cpus** is the speed of CPU (e.g. 4096) in terms of MHz of your VM to be instantiated. The CPU frequency required to be between 250 and 100000
*  **mem_size** is the amount of RAM (e.g. 4294967296) in terms of bytes to be allocated for your VM. The memory required to be between 268435456 and 137438953472
*  **vnc_password** set the password for your VNC session (e.g. secret).
*  **libdrive_id** is the image id (e.g. 87ce928e-e0bc-4cab-9502-514e523783e3) on your CloudSigma cloud. Select an image containing a base os installation with cloud-init support!
*  **public_key_id** specifies the keypairs (e.g. d7c0f1ee-40df-4029-8d95-ec35b34dae1e) to be assigned to your VM.
*  **nics[.firewall_policy | .ip_v4_conf.conf]**  specifies network policies (you can define multiple security groups in the form of a list for your VM).


CloudBroker
~~~~~~~~~~~

To instantiate MiCADO workers on CloudBroker, please use the template below. MiCADO **requires** deployment_id and instance_type_id to instantiate a VM on *CloudBroker*.

::

  YOUR-VIRTUAL-MACHINE:
    type: tosca.nodes.MiCADO.CloudBroker.Compute
      properties:
        deployment_id: ADD_YOUR_ID_HERE (e.g. e7491688-599d-4344-95ef-aff79a60890e)
        instance_type_id: ADD_YOUR_ID_HERE (e.g. 9b2028be-9287-4bf6-bbfe-bcbc92f065c0)
        key_pair_id: ADD_YOUR_ID_HERE (e.g. d865f75f-d32b-4444-9fbb-3332bcedeb75)
        opened_port: ADD_YOUR_PORTS_HERE (e.g. '22,2377,7946,8300,8301,8302,8500,8600,9100,9200,4789')
      capabilities:
      # OPTIONAL METADATA
        host:
          properties:
            num_cpus: 2GHz
            mem_size: 2GB
        os:
          properties:
            type: linux
            distribution: ubuntu
            version: 16.04
      interfaces:
        Occopus:
          create:
            inputs:
              interface_cloud: cloudbroker
              endpoint_cloud: ADD_YOUR_ENDPOINT (e.g https://cola-prototype.cloudbroker.com )

Under the **properties** section of a CloudBroker virtual machine definition these inputs are available.:

*  **deployment_id** is the id of a preregistered deployment in CloudBroker referring to a cloud, image, region, etc. Make sure the image contains a base OS (preferably Ubuntu) installation with cloud-init support! The id is the UUID of the deployment which can be seen in the address bar of your browser when inspecting the details of the deployment.
*  **instance_type_id** is the id of a preregistered instance type in CloudBroker referring to the capacity of the virtual machine to be deployed. The id is the UUID of the instance type which can be seen in the address bar of your browser when inspecting the details of the instance type.
*  **key_pair_id** is the id of a preregistered ssh public key in CloudBroker which will be deployed on the virtual machine. The id is the UUID of the key pair which can be seen in the address bar of your browser when inspecting the details of the key pair.
*  **opened_port** is one or more ports to be opened to the world. This is a string containing numbers separated by a comma.

EC2
~~~

To instantiate MiCADO workers on a cloud through EC2 interface, please use the template below. MiCADO **requires** region_name, image_id and instance_type to instantiate a VM through *EC2*.

::

  YOUR-VIRTUAL-MACHINE:
    type: tosca.nodes.MiCADO.EC2.Compute
    properties:
          region_name: ADD_YOUR_REGION_NAME_HERE (e.g. eu-west-1)
          image_id: ADD_YOUR_ID_HERE (e.g. ami-12345678)
          instance_type: ADD_YOUR_INSTANCE_TYPE_HERE (e.g. t1.small)
    capabilities:
    # OPTIONAL METADATA
      host:
        properties:
          num_cpus: 2GHz
          mem_size: 2GB
      os:
        properties:
          type: linux
          distribution: ubuntu
          version: 16.04
    interfaces:
      Occopus:
        create:
          inputs:
            interface_cloud: ec2
            endpoint_cloud: ADD_YOUR_ENDPOINT (e.g https://ec2.eu-west-1.amazonaws.com)

Under the **properties** section of an EC2 virtual machine definition these inputs are available.:

*  **region_name** is the region name within an EC2 cloud (e.g. eu-west-1).
*  **image_id** is the image id (e.g. ami-12345678) on your EC2 cloud. Select an image containing a base os installation with cloud-init support!
*  **instance_type** is the instance type (e.g. t1.small) of your VM to be instantiated.
*  **key_name** optionally specifies the keypair (e.g. my_ssh_keypair) to be deployed on your VM.
*  **security_group_ids** optionally specify security settings (you can define multiple security groups or just one, but this property must be formatted as a list, e.g. [sg-93d46bf7]) of your VM.
*  **subnet_id** optionally specifies subnet identifier (e.g. subnet-644e1e13) to be attached to the VM.

Nova
~~~~

To instantiate MiCADO workers on a cloud through Nova interface, please use the template below. MiCADO **requires** image_id flavor_name, project_id and network_id to instantiate a VM through *Nova*.

::

  YOUR-VIRTUAL-MACHINE:
    type: tosca.nodes.MiCADO.Nova.Compute
    properties:
          image_id: ADD_YOUR_ID_HERE (e.g. d4f4e496-031a-4f49-b034-f8dafe28e01c)
          flavor_name: ADD_YOUR_ID_HERE (e.g. 3)
          project_id: ADD_YOUR_ID_HERE (e.g. a678d20e71cb4b9f812a31e5f3eb63b0)
          network_id: ADD_YOUR_ID_HERE (e.g. 3fd4c62d-5fbe-4bd9-9a9f-c161dabeefde)
          key_name: ADD_YOUR_KEY_HERE (e.g. keyname)
          security_groups:
            - ADD_YOUR_ID_HERE (e.g. d509348f-21f1-4723-9475-0cf749e05c33)
    capabilities:
    # OPTIONAL METADATA
      host:
        properties:
          num_cpus: 2GHz
          mem_size: 2GB
      os:
        properties:
          type: linux
          distribution: ubuntu
          version: 16.04
    interfaces:
      Occopus:
        create:
          inputs:
            interface_cloud: nova
            endpoint_cloud: ADD_YOUR_ENDPOINT (e.g https://sztaki.cloud.mta.hu:5000/v3)

Under the **properties** section of a Nova virtual machine definition these inputs are available.:

*  **project_id** is the id of project you would like to use on your target Nova cloud.
*  **image_id** is the image id on your Nova cloud. Select an image containing a base os installation with cloud-init support!
*  **flavor_name** is the name of flavor to be instantiated on your Nova cloud.
*  **server_name** optionally defines the hostname of VM (e.g.:”helloworld”).
*  **key_name** optionally sets the name of the keypair to be associated to the instance. Keypair name must be defined on the target nova cloud before launching the VM.
*  **security_groups** optionally specify security settings (you can define multiple security groups in the form of a list) for your VM.
*  **network_id** is the id of the network you would like to use on your target Nova cloud.

Types
~~~~~

**NEW in v0.8.0** Through abstraction, it is possible to reference a
pre-defined type and simplify the description of a virtual machine. Currently
MiCADO supports these additional types for CloudSigma, but more can be written:

* **tosca.nodes.MiCADO.CloudSigma.Compute.Occo** -
  Automatically orchestrates on Zurich with Occopus. There is no need to
  define further fields under **interfaces:** but Zurich can be changed
  by overwriting **endpoint** under **properties:**
* **tosca.nodes.MiCADO.CloudSigma.Compute.Occo.small** -
  As above but creates a 2GHz/2GB node by default
* **tosca.nodes.MiCADO.CloudSigma.Compute.Occo.big** -
  As above but creates a 4GHz/4GB node by default
* **tosca.nodes.MiCADO.CloudSigma.Compute.Occo.small.NFS** -
  As *small* above but installs NFS dependencies by default

Example definition of a VM using abstraction
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**With** *tosca.nodes.MiCADO.CloudSigma.Compute.Occo.small*
and omitting capabilities metadata

::

  YOUR-VIRTUAL-MACHINE:
    type: tosca.nodes.MiCADO.CloudSigma.Compute.Occo.small
      properties:
        vnc_password: ADD_YOUR_PW (e.g. secret)
        libdrive_id: ADD_YOUR_ID_HERE (eg. 87ce928e-e0bc-4cab-9502-514e523783e3)
        public_key_id: ADD_YOUR_ID_HERE (e.g. d7c0f1ee-40df-4029-8d95-ec35b34dae1e)
        nics:
        - firewall_policy: ADD_YOUR_FIREWALL_POLICY_ID_HERE (e.g. fd97e326-83c8-44d8-90f7-0a19110f3c9d)
          ip_v4_conf:
            conf: dhcp

Specification of Policies
-----------------------------------

Monitoring Policies
~~~~~~~~~~~~~~~~~~~

**NEW in v0.8.0** Metric collection is now disabled by default. The basic
exporters from previous MiCADO versions can be enabled through the monitoring
policy below. If the policy is omitted, or if one property is left undefined,
then the relevant metric collection will be disabled.

::

  policies:
  - monitoring:
      type: tosca.policies.Monitoring.MiCADO
      properties:
        enable_container_metrics: true
        enable_node_metrics: true


Scaling Policies
~~~~~~~~~~~~~~~~

To utilize the autoscaling functionality of MiCADO, scaling policies can be defined on virtual machine and on the application level. Scaling policies can be listed under the **policies** section. Each **scalability** subsection must have the **type** set to the value of ``tosca.policies.Scaling.MiCADO`` and must be linked to a node defined under **node_template**. The link can be implemented by specifying the name of the node under the **targets** subsection. You can attach different policies to different containers or virtual machines, though a new policy should exist for each. The details of the scaling policy can be defined under the **properties** subsection. The structure of the **policies** section can be seen below.

::

   topology_template:
     node_templates:
       YOUR-VIRTUAL-MACHINE:
         type: tosca.nodes.MiCADO.<CLOUD_API_TYPE>.Compute
         ...
       YOUR-OTHER-VIRTUAL-MACHINE:
         type: tosca.nodes.MiCADO.<CLOUD_API_TYPE>.Compute
         ...
       YOUR-KUBERNETES-APP:
         type: tosca.nodes.MiCADO.Container.Application.Docker
         ...
       YOUR-OTHER-KUBERNETES-APP:
         type: tosca.nodes.MiCADO.Container.Application.Docker
         ...

     policies:
     - scalability:
        type: tosca.policies.Scaling.MiCADO
        targets: [ YOUR-VIRTUAL-MACHINE ]
        properties:
          ...
     - scalability:
        type: tosca.policies.Scaling.MiCADO
        targets: [ YOUR-OTHER-VIRTUAL-MACHINE ]
        properties:
          ...
     - scalability:
        type: tosca.policies.Scaling.MiCADO
        targets: [ YOUR-KUBERNETES-APP ]
        properties:
          ...
     - scalability:
        type: tosca.policies.Scaling.MiCADO
        targets: [ YOUR-OTHER-KUBERNETES-APP ]
        properties:
          ...

The scaling policies are evaluated periodically. In every turn, the virtual machine level scaling policies are evaluated, followed by the evaluation of each scaling policies belonging to kubernetes-deployed applications.

The **properties** subsection defines the scaling policy itself. For monitoring purposes, MiCADO integrates the Prometheus monitoring tool with two built-in exporters on each worker node: Node exporter (to collect data on nodes) and CAdvisor (to collect data on containers). Based on Prometheus, any monitored information can be extracted using the Prometheus query language and the returned value can be associated to a user-defined variable. Once variables are updated, scaling rule is evaluated. Scaling rule is specified by (a short) Python code. The code can refer to/use the variables. The structure of the scaling policy can be seen below.

::

     - scalability:
         ...
         properties:
           sources:
             - 'myprometheus.exporter.ip.address:portnumber'
           constants:
             LOWER_THRESHOLD: 50
             UPPER_THRESHOLD: 90
             MYCONST: 'any string'
           queries:
             THELOAD: 'Prometheus query expression returning a number'
             MYLISTOFSTRING: ['Prometheus query returning a list of strings as tags','tagname as filter']
             MYEXPR: 'something refering to {{MYCONST}}'
           alerts:
             - alert: myalert
               expr: 'Prometheus expression for an event important for scaling'
               for: 1m
           min_instances: 1
           max_instances: 5
           scaling_rule: |
             if myalert:
               m_node_count=5
             if THELOAD>UPPER_THRESHOLD:
               m_node_count+=1
             if THELOAD<LOWER_THRESHOLD:
               m_node_count-=1

The subsections have the following roles:

* **sources** supports the dynamic attachment of an external exporter by specifying a list endpoints of exporters (see example above). Each item found under this subsection is configured under Prometheus to start collecting the information provided/exported by the exporters. Once done, the values of the parameters provided by the exporters become available. MiCADO supports Kubernetes service discovery to define such a source, simply pass the name of the app as defined in TOSCA and do not specify any port number
* **constants** subsection is used to predefined fixed parameters. Values associated to the parameters can be referred by the scaling rule as variable (see ``LOWER_THRESHOLD`` above) or in any other sections referred as Jinja2 variable (see ``MYEXPR`` above).
* **queries** contains the list of Prometheus query expressions to be executed and their variable name associated (see ``THELOAD`` or ``MYLISTOFSTRING`` above)
* **alerts** subsection enables the utilization of the alerting system of Prometheus. Each alert defined here is registered under Prometheus and fired alerts are represented with a variable of their name set to True during the evaluation of the scaling rule (see ``myalert`` above).
* **min_instances** keyword specifies the lowest number of instances valid for the node.
* **max_instances** keyword specifies the highest number of instances valid for the node.
* **scaling_rule** specifies Python code to be evaluated periodically to decide on the number of instances. The Python expression must be formalized with the following conditions:

  - Each constant defined under the ‘constants’ section can be referred; its value is the one defined by the user.
  - Each variable defined under the ‘queries’ section can be referred; its value is the result returned by Prometheus in response to the query string.
  - Each alert name defined under the ‘alerts’ section can be referred, its value is a logical True in case the alert is firing, False otherwise
  - Expression must follow the syntax of the Python language
  - Expression can be multiline
  - The following predefined variables can be referred; their values are defined and updated before the evaluation of the scaling rule

    - m_nodes: python list of nodes belonging to the kubernetes cluster
    - m_node_count: the target number of nodes
    - m_nodes_todrop: the ids or ip addresses of the nodes to be dropped in case of downscaling
    - m_container_count: the target number of containers for the service the evaluation belongs to
    - m_time_since_node_count_changed: time in seconds elapsed since the number of nodes changed

  - In a scaling rule belonging to the virtual machine, the name of the variable to be updated is ``m_node_count``; as an effect the number stored in this variable will be set as target instance number for the virtual machines.
  - In a scaling rule belonging to the virtual machine, the name of the variable to be updated is ``m_nodes_todrop``;the variable must be filled with list of ids or ip addresses and as an effect the valid nodes will be dropped. The variable ``m_node_count`` should not be modified in case of node dropping, MiCADO will update it automatically.
  - In a scaling rule belonging to a kubernetes deployment, the name of the variable to be set is ``m_container_count``; as an effect the number stored in this variable will be set as target instance number for the kubernetes service.
  
For debugging purposes, the following support is provided:

* ``m_dryrun`` can be specified in the **constant** as list of components towards which the communication is disabled. It has the following syntax: m_dryrun: ["prometheus","occopus","k8s","optimizer"] Use this feature with caution!

* the standard output of the python code defined by the user under the scaling rule section is collected in a separate log file stored under the policy keeper log directory. It can also be used for debugging purposes.

For further examples, inspect the scaling policies of the demo examples detailed in the next section.

Utilization of the Optimiser for scaling
========================================

For implementing more advanced scaling policies, it is possible to utilize the built-in Optimiser in MiCADO. The role of the Optimiser is to support decision making in calculating the number of worker nodes (virtual machines) i.e. to scale the nodes to the optimal level. Optimiser is implemented using machine learning algorithm aiming to learn the relation between various metrics and the effect of scaling events. Based on this learning, the Optimiser is able to calculate and advise on the necessary number of virtual machines.

Current limitations
  - only web based applications are supported
  - only one of the node sets can be supported 
  - no container scaling is supported

Optimiser can be utilised based on the following principles 
  - User specifies a so-called target metric with its associated minimum and maximum thresholds. The target metric is a monitored Prometheus expression for which the value is tried to be kept between the two thresholds by the Optimiser with scaling advices.
  - User specifies several so-called input metrics which represent the state of the system correlating to the target variable
  - User specifies several initial settings (see later) for the Optimiser
  - User submits the application activating the Optimiser through the ADT
  - Optimiser starts with the 'training' phase during which the correlations are learned. During the training phase artificial load must be generated for the web application and scaling activities must be performed (including extreme values) in order to present all possible situations for the Optimiser. During the phase, Optimiser continuously monitors the input/target metrics and learns the correlations.
  - When correlations are learnt, Optimiser turns to 'production' phase during which advice can be requested from the Optimiser. During this phase, Optimiser returns advice on request, where the advice contains the number of virtual machines (nodes) to be scaled to. During the production phase, the Optimiser continues its learning activity to adapt to the new situations.

Activation of the Optimiser
  Optimiser-related parameters must be inserted into the scaling policy to subsections "constants" and "queries". Each parameter relating to the Optimiser must start with the "m_opt\_" string. In case no variable name with this prefix is found in any sections, Optimiser is not activated.

Initial settings for the Optimiser
  Parameters for initial settings are defined under the "constants" section and their name must start with the "m_opt_init\_" prefix. These parameters are as follows:

  - **m_opt_init_knowledge_base** is a parameter which specifies the way how the knowledge base must be built under the Optimiser. When defined as "build_new", Optimiser empties its knowledge base and starts building a new knowledge i.e. starts learning the correlations. When using the "use_existing" value, the knowledge is kept and continued building further. Default is "use_existing".
  - **m_opt_init_training_samples_required** defines how many sample of the metrics must be collected by the Optimiser before start learning the correlations. Default is 300.
  - **m_opt_init_max_upscale_delta** specifies the maximum change in number of node for an upscaling advice. Default is 6.
  - **m_opt_init_max_downscale_delta** specifies the maximum change in number of node for a downscaling advice. Default is 6.
  - **m_opt_init_advice_freeze_interval** specifies how many seconds must elapse before the Optimiser advises a different number of node. Can be used to mitigate the frequency of scaling. Defaults to 0.

Definition of input metrics for the Optimizer
  Input metrics must be specified for the Optimiser under the "queries" subsection to perform the training i.e. learning the correlations. Each parameter must start with the "m_opt_input\_" prefix, e.g. m_opt_input_CPU. The following two pieces of variable must be specified for the web application:

  - **m_opt_input_AVG_RR** should specify the average request rate of the web server.
  - **m_opt_input_SUM_RR** should specify the summary of request rate of the web server.

Definition of the target metric for the Optimizer
  Target metric is a continuously monitored parameter that must be kept between thresholds. To specify it, together with the thresholds, "m_opt_target\_" prefix must be used. These three parameter must be defined under the "queries" sections. They are as follows:

  - **m_opt_target_query_MYTARGET** specifies the prometheus query for the target metric called MYTARGET.
  - **m_opt_target_minth_MYTARGET** specifies the value above which the target metric must be kept.
  - **m_opt_target_maxth_MYTARGET** specifies the value below which the target metric must be kept.

Requesting scaling advice from the Optimizer
  In order to receive a scaling advice from the Optimiser, the method **m_opt_advice()** must be invoked in the scaling_rule section of the node. 

  **IMPORTANT! Minimum and maximum one node must contain this method invocation in its scaling_rule section for proper operation!**

  The **m_opt_advice()** method returns a python dictionary containing the following fields:

  - **valid** stores True/False value indicating whether the advise can be considered or not.
  - **phase** indicates whether the Optimiser is in "training" or "production" phase.
  - **vm_number** represents the advise for the target number of nodes to scale to.
  - **reliability** represents the goodness of the advice with a number between 0 and 100. The bigger the number is the better/more reliable the advice is.
  - **error_msg** contains the error occured in the Optimiser. Filled when valid is False.




  



