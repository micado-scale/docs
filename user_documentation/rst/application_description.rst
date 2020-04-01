.. _applicationdescription:


Application Description Template (ADT)
======================================

Overview
--------

MiCADO executes applications described by Application Description Template.
The ADT follows the `TOSCA Specification
<http://docs.oasis-open.org/tosca/TOSCA-Simple-Profile-YAML/v1.2/TOSCA-Simple-Profile-YAML-v1.2.pdf>`_
and is described in detail in this section.

Main sections of the ADT
~~~~~~~~~~~~~~~~~~~~~~~~

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
     - https://raw.githubusercontent.com/micado-scale/tosca/v0.8.1/micado_types.yaml

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
     - monitoring:
         type: tosca.policies.Monitoring.MiCADO
         properties:
           enable_container_metrics: true
           enable_node_metrics: false
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
     - network:
         type: tosca.policies.Security.MiCADO.Network.HttpProxy
         properties:
           encryption: true
           encryption_key: |
             -----BEGIN PRIVATE KEY-----
             ...
     - secret:
         type: tosca.policies.Security.MiCADO.Secret.KubernetesSecretDistribution
         properties:
           ...

Application
-----------

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
  * **valueFrom:** **!! see note below**
* **envFrom**: **!! see note below**
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

Environment variables can be loaded in from configuration
data in Kubernetes ConfigMaps. This can be accomplished by using **envFrom:**
with a list of **configMapRef:** to load all data from a ConfigMap into
environment variables as seen
`here <https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#configure-all-key-value-pairs-in-a-configmap-as-container-environment-variables>`__
, or by using **env:** and **valueFrom:**  with **configMapKeyRef:** to load
specific values into environment variables as seen
`here <https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#define-container-environment-variables-using-configmap-data>`__
.

Alternatively, ConfigMaps can be mounted as volumes as discussed
`here <https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#add-configmap-data-to-a-volume>`__
, in the same way other volumes are attached to a container, using the
**requirements:** notation below. Also see the examples in **Specification**
**of Configuration Data** below.


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
will run on any possible virtual machine. You can also attach a volume or
ConfigMap to this app - the definition of volumes can be found in the next
section. Requirements takes a list of map objects:

* **host:** name of your virtual machine as defined under node_templates
* **volume:**

  * **node:** name of your volume (or ConfigMap) as defined under
    node_templates
  * **relationship:** **!!**

    * **type:** ``tosca.relationships.AttachesTo``
    * **properties:**

      * **location:** path in container

* **container:** name of a sidecar container defined as a
  ``tosca.nodes.MiCADO.Container.Application.Docker`` type under
  node_templates. The sidecar will share the Kubernetes Pod with
  the main container (the sidecar should not be given an interface)

If a relationship is not defined for a volume the
path on container will be the same as the path defined in the volume
(see Specification of Volumes). If no path is defined in the volume,
the path defaults to */etc/micado/volumes* for a Volume or
*/etc/micado/configs* for a ConfigMap

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

Through abstraction, it is possible to reference a
pre-defined parent type and simplify the description of a container. These
parent types can hide or reduce the complexity of more complex TOSCA constructs
such as **artifacts** and **interfaces** by enforcing defaults or moving them
to a simpler construct such as **properties**. Currently MiCADO supports the
following types:

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

Volume
------
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

Through abstraction, it is possible to reference a
pre-defined parent type and simplify the description of a volume. These
parent types can hide or reduce the complexity of more complex TOSCA constructs
such as  **interfaces** by enforcing defaults or moving them
to a simpler construct such as **properties**. Currently MiCADO supports the
following volume types:

* **tosca.nodes.MiCADO.Container.Volume** -
  The base and most common type for volumes in MiCADO. It is
  necessary to define further fields under **interfaces:**
* **tosca.nodes.MiCADO.Container.Volume.EmptyDir** -
  Creates a `EmptyDir <https://kubernetes.io/docs/concepts/storage/volumes/#emptydir>`__
  persistent volume (PV) and claim (PVC) in Kubernetes
* **tosca.nodes.MiCADO.Container.Volume.HostPath** -
  Creates a `HostPath <https://kubernetes.io/docs/concepts/storage/volumes/#hostpath>`__
  PV and PVC. Define the path on host as **path:** under **properties:**
* **tosca.nodes.MiCADO.Container.Volume.NFS** -
  Creates an `NFS <https://kubernetes.io/docs/concepts/storage/volumes/#nfs>`__
  PV and PVC. Define the path and server IP as **path:** and **server:**
  under **properties:**
* **tosca.nodes.MiCADO.Container.Volume.GlusterFS** -
  Creates a `GlusterFS <https://kubernetes.io/docs/concepts/storage/volumes/#glusterfs>`__
  PV and PVC. Define path, endpoint and readOnly flag as **path:**,
  **endpoints:**, and **readOnly:** under **properties:**

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

Configuration Data
------------------

Configuration data (a Kubernetes **ConfigMap**) are to be defined at the same
level as virtual machines, containers and volumes and then loaded into
environment variables, or mounted as volumes in the definition of containers
as discussed in **Specification of the Application**.
Some examples of using configurations will follow at the end of this section.

Interfaces
~~~~~~~~~~

Currently MiCADO only supports the definition of configuration
data as Kubernetes ConfigMaps. Under the
**interfaces** section of this type use the key **Kubernetes:**
to instruct MiCADO to create a ConfigMap.

* **create**: *this key tells MiCADO to create a ConfigMap*

  * **inputs**: ConfigMap fields to be overwritten, for more detail see
    `ConfigMap <https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.15/#configmap-v1-core>`__

    * **data:** for UTF-8 byte values
    * **binaryData:** for byte values outside of the UTF-8 range

Types
~~~~~

Through abstraction, it is possible to reference a
pre-defined parent type and simplify the description of a ConfigMap.
These parent types can hide or reduce the complexity of more complex TOSCA
constructs such as **interfaces** by enforcing defaults or moving them
to a simpler construct such as **properties**. Currently MiCADO supports the
following ConfigMap types:

* **tosca.nodes.MiCADO.Container.Config** -
  The base and most common type for configuration data in MiCADO. It is
  necessary to define further fields under **interfaces:** as indicated above
* **tosca.nodes.MiCADO.Container.Config.Kubernetes** -
  Defaults to a Kubernetes interface and abstracts the inputs to properties.
  Define the data or binary data fields as **data:** and **binaryData:**
  under **properties:**

Examples of the definition of a simple ConfigMap
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Single ENV var with** *tosca.nodes.MiCADO.Container.Config*

  Here the environment variable MY_COLOUR is assigned a value
  from the ConfigMap

::

  YOUR-CONFIG:
    type: tosca.nodes.MiCADO.Container.Config
    interfaces:
      Kubernetes:
        create:
          inputs:
            data:
              color: purple
              how: fairlyNice
              textmode: "true"

  YOUR-KUBERNETES-APP:
    type: tosca.nodes.MiCADO.Container.Application.Docker.Deployment
    properties:
      env:
      - name: MY_COLOUR
        valueFrom:
          configMapKeyRef:
            name: YOUR-CONFIG
            key: color

**All ENV vars with** *tosca.nodes.MiCADO.Container.Config.Kubernetes*

  Here an environment variable is created for each key (this becomes the
  variable name) and value pair in the ConfigMap

::

  YOUR-CONFIG:
    type: tosca.nodes.MiCADO.Container.Config.Kubernetes
    properties:
      data:
        color: purple
        how: fairlyNice
        textmode: "true"

  YOUR-KUBERNETES-APP:
    type: tosca.nodes.MiCADO.Container.Application.Docker.Deployment
    properties:
      envFrom:
      - configMapRef:
            name: YOUR-CONFIG

**A volume with** *tosca.nodes.MiCADO.Container.Config.Kubernetes*

  Here a volume at /etc/config is populated with three files named
  after the ConfigMap key names and containing the matching values

::

  YOUR-CONFIG:
    type: tosca.nodes.MiCADO.Container.Config.Kubernetes
    properties:
      data:
        color: purple
        how: fairlyNice
        textmode: "true"

  YOUR-KUBERNETES-APP:
    type: tosca.nodes.MiCADO.Container.Application.Docker.Deployment
    requirements:
    - volume:
        node: YOUR-CONFIG
        relationship:
          type: tosca.relationships.AttachesTo
          properties:
            location: /etc/config

Virtual Machine
---------------

The collection of docker containers (kubernetes applications) specified in the
previous section is orchestrated by Kubernetes. This section introduces how the
parameters of the virtual machine can be configured which will host the
Kubernetes worker node. During operation MiCADO will instantiate as many
virtual machines with the parameters defined here as required during scaling.
MiCADO currently supports six different cloud interfaces: CloudSigma,
CloudBroker, EC2, Nova, Azure and GCE. MiCADO supports multiple virtual machine
"sets" which can be restricted to host only specific containers (defined in the
requirements section of the container specification). At the moment multi-cloud
support is in alpha stage, so only certain combinations of different cloud
service providers will work.

**NOTE** Underscores are not permitted in virtual machine names
(ie TOSCA node names). Names should also begin and end with an alphanumeric.

.. _workerfirewallconfig:

The following ports and protocols should be enabled on the virtual machine
acting as MiCADO worker, replacing [exposed_application_ports] with ports you
wish to expose on the host:

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

**Here is the basic look of a Virtual Machine node inside an ADT:**

::

  SAMPLE-VIRTUAL-MACHINE:
    type: tosca.nodes.MiCADO...Compute
      properties:
        <CLOUD-SPECIFIC VM PROPERTIES>

      capabilities:
        host:
          properties:
            num_cpus: 2
            mem_size: 4 GB
        os:
          properties:
            type: linux
            distribution: ubuntu
            version: 18.04

      interfaces:
        Occopus:
          create:
            inputs:
              endpoint: https://mycloud/api/v1

The **properties** section is **REQUIRED** and contains the necessary
properties to provision the virtual machine and vary from cloud to cloud.
Properties for each cloud are detailed further below.

The **capabilities** sections for all virtual machine definitions that follow
are identical and are **ENTIRELY OPTIONAL**. They are ommited in the
cloud-specific examples below. They are filled with the following metadata to
support human readability:

* **num_cpus** under *host* is an integer specifying number of CPUs for
  the instance type
* **mem_size** under *host* is a readable string with unit specifying RAM of
  the instance type
* **type** under *os* is a readable string specifying the operating system
  type of the image
* **distribution** under *os* is a readable string specifying the OS distro
  of the image
* **version** under *os* is a readable string specifying the OS version of
  the image

The **interfaces** section of all virtual machine definitions that follow
are **REQUIRED**, and allow you to provide orchestrator specific inputs, in
the examples we use either **Occopus** or **Terraform** based on suitability.

* **create**: *this key tells MiCADO to create the VM using Occopus/Terraform*

  * **inputs**: Extra settings to pass to Occopus or Terraform

    * **endpoint:** the endpoint API of the cloud (always required for
      Occopus, sometimes required for Terraform)


CloudSigma
~~~~~~~~~~

To instantiate MiCADO workers on CloudSigma, please use the template below.
MiCADO **requires** num_cpus, mem_size, vnc_password, libdrive_id,
public_key_id and firewall_policy to instantiate VM on *CloudSigma*.

Currently, only **Occopus** has support for CloudSigma, so Occopus must be
enabled as in :ref:`customize`, and the interface must be set to Occopus as
in the example below.

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

      interfaces:
        Occopus:
          create:
            inputs:
              endpoint: ADD_YOUR_ENDPOINT (e.g for cloudsigma https://zrh.cloudsigma.com/api/2.0 )

Under the **properties** section of a CloudSigma virtual machine definition
these inputs are available.:

* **num_cpus** is the speed of CPU (e.g. 4096) in terms of MHz of your VM
  to be instantiated. The CPU frequency required to be between 250 and 100000
* **mem_size** is the amount of RAM (e.g. 4294967296) in terms of bytes to be
  allocated for your VM. The memory required to be between 268435456 and
  137438953472
* **vnc_password** set the password for your VNC session (e.g. secret).
* **libdrive_id** is the image id (e.g. 87ce928e-e0bc-4cab-9502-514e523783e3)
  on your CloudSigma cloud. Select an image containing a base os installation
  with cloud-init support!
* **public_key_id** specifies the keypairs
  (e.g. d7c0f1ee-40df-4029-8d95-ec35b34dae1e) to be assigned to your VM.
* **nics[.firewall_policy && .ip_v4_conf.conf]**  specifies network policies
  (you can define multiple security groups in the form of a list for your VM).


CloudBroker
~~~~~~~~~~~

To instantiate MiCADO workers on CloudBroker, please use the template below.
MiCADO **requires** deployment_id and instance_type_id to instantiate a VM on
*CloudBroker*.

Currently, only **Occopus** has support for CloudBroker, so Occopus must be
enabled as in :ref:`customize` and the interface must be set to Occopus as
in the example below.

::

  YOUR-VIRTUAL-MACHINE:
    type: tosca.nodes.MiCADO.CloudBroker.Compute
      properties:
        deployment_id: ADD_YOUR_ID_HERE (e.g. e7491688-599d-4344-95ef-aff79a60890e)
        instance_type_id: ADD_YOUR_ID_HERE (e.g. 9b2028be-9287-4bf6-bbfe-bcbc92f065c0)
        key_pair_id: ADD_YOUR_ID_HERE (e.g. d865f75f-d32b-4444-9fbb-3332bcedeb75)
        opened_port: ADD_YOUR_PORTS_HERE (e.g. '22,2377,7946,8300,8301,8302,8500,8600,9100,9200,4789')

      interfaces:
        Occopus:
          create:
            inputs:
              endpoint: ADD_YOUR_ENDPOINT (e.g https://cola-prototype.cloudbroker.com )

Under the **properties** section of a CloudBroker virtual machine definition
these inputs are available.:

* **deployment_id** is the id of a preregistered deployment in CloudBroker
  referring to a cloud, image, region, etc. Make sure the image contains a
  base OS (preferably Ubuntu) installation with cloud-init support! The id is
  the UUID of the deployment which can be seen in the address bar of your
  browser when inspecting the details of the deployment.
* **instance_type_id** is the id of a preregistered instance type in
  CloudBroker referring to the capacity of the virtual machine to be deployed.
  The id is the UUID of the instance type which can be seen in the address bar
  of your browser when inspecting the details of the instance type.
* **key_pair_id** is the id of a preregistered ssh public key in CloudBroker
  which will be deployed on the virtual machine. The id is the UUID of the key
  pair which can be seen in the address bar of your browser when inspecting the
  details of the key pair.
* **opened_port** is one or more ports to be opened to the world. This is a
  string containing numbers separated by a comma.

EC2
~~~

To instantiate MiCADO workers on a cloud through EC2 interface, please use the
template below. MiCADO **requires** region_name, image_id and instance_type to
instantiate a VM through *EC2*.

Both **Occopus and Terraform** support EC2 provisioning. To use Terraform,
enable it as described in :ref:`customize` and adjust the interfaces section
accordingly.

::

  YOUR-VIRTUAL-MACHINE:
    type: tosca.nodes.MiCADO.EC2.Compute
    properties:
          region_name: ADD_YOUR_REGION_NAME_HERE (e.g. eu-west-1)
          image_id: ADD_YOUR_ID_HERE (e.g. ami-12345678)
          instance_type: ADD_YOUR_INSTANCE_TYPE_HERE (e.g. t1.small)

    interfaces:
      Occopus:
        create:
          inputs:
            endpoint: ADD_YOUR_ENDPOINT (e.g https://ec2.eu-west-1.amazonaws.com)

Under the **properties** section of an EC2 virtual machine definition these
inputs are available.:

* **region_name** is the region name within an EC2 cloud (e.g. eu-west-1).
* **image_id** is the image id (e.g. ami-12345678) on your EC2 cloud. Select an
  image containing a base os installation with cloud-init support!
* **instance_type** is the instance type (e.g. t1.small) of your VM to be
  instantiated.
* **key_name** optionally specifies the keypair (e.g. my_ssh_keypair) to be
  deployed on your VM.
* **security_group_ids** optionally specify security settings (you can define
  multiple security groups or just one, but this property must be formatted as
  a list, e.g. [sg-93d46bf7]) of your VM.
* **subnet_id** optionally specifies subnet identifier (e.g. subnet-644e1e13)
  to be attached to the VM.

Under the **interfaces** section of an EC2 virtual machine definition, the
**endpoint** input is required by Occopus as seen in the example above.

For Terraform the endpoint is discovered automatically based on region.
To customise the endpoint (e.g. for OpenNebula) pass the **endpoint** input
in interfaces.

::

  ...
    interfaces:
      Terraform:
        create:
          inputs:
            endpoint: ADD_YOUR_ENDPOINT (e.g https://my-custom-endpoint/api)

Nova
~~~~

To instantiate MiCADO workers on a cloud through Nova interface, please use the
template below. MiCADO **requires** image_id, flavor_name, project_id and
network_id to instantiate a VM through *Nova*.

Both **Occopus and Terraform** support Nova provisioning. To use Terraform,
enable it as described in :ref:`customize` and adjust the interfaces section
accordingly.

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

    interfaces:
      Occopus:
        create:
          inputs:
            endpoint: ADD_YOUR_ENDPOINT (e.g https://sztaki.cloud.mta.hu:5000/v3)

Under the **properties** section of a Nova virtual machine definition these
inputs are available.:

* **project_id** is the id of project you would like to use on your target
  Nova cloud.
* **image_id** is the image id on your Nova cloud. Select an image containing
  a base os installation with cloud-init support!
* **flavor_name** is the id of the desired flavor for the VM.
* **tenant_name** is the name of the Tenant or Project to login with.
* **user_domain_name** is the domain name where the user is located.
* **availability_zone** is the availability zone in which to create the VM.
* **server_name** optionally defines the hostname of VM (e.g.:”helloworld”).
* **key_name** optionally sets the name of the keypair to be associated to the
  instance. Keypair name must be defined on the target nova cloud before
  launching the VM.
* **security_groups** optionally specify security settings (you can define
  multiple security groups in the form of a **list**) for your VM.
* **network_id** is the id of the network you would like to use on your target
  Nova cloud.

Under the **interfaces** section of a Nova virtual machine definition, the
**endpoint** input (v3 Identity service) is required as seen in the
example above.

For Terraform the endpoint should also be passed as **endpoint**  in inputs.
Depending on the configuration of the OpenStack cluster, it may be necessary
to provide **network_name** in addition to the ID.

::

  ...
    interfaces:
      Terraform:
        create:
          inputs:
            endpoint: ADD_YOUR_ENDPOINT (e.g https://sztaki.cloud.mta.hu:5000/v3)
            network_name: ADD_YOUR_NETWORK_NAME (e.g mynet-default)

**Authentication** in OpenStack is supported by MiCADO in two ways:

  The default method is authenticating with the same credentials
  used to access the OpenStack WebUI by providing
  the **username** and **password** fields in *credentials-cloud-api.yml*
  during :ref:`cloud-credentials`

  The other option is with `Application Credentials <https://docs.openstack.org/keystone/queens/user/application_credentials.html>`__
  For this method, provide **application_credential_id** and
  **applicaiton_credential_secret** in *credentials-cloud-api.yml*.
  If these fields are filled, **username** and **password** will be
  ignored.

Azure
~~~~~

To instantiate MiCADO workers on a cloud through Azure interface, please
use the template below. Currently, only **Terraform** has support for Azure,
so Terraform must be enabled as in :ref:`customize`, and the interface must
be set to Terraform as in the example below.

MiCADO supports Windows VM provisioning in Azure. To force a Windows VM,
simply **DO NOT** pass the **public_key** property and **set the image** to
a desired WindowsServer Sku (2016-Datacenter). `Refer to this Sku list <https://docs.microsoft.com/en-us/azure/virtual-machines/windows/cli-ps-findimage#table-of-commonly-used-windows-images>`__

::

  YOUR-VIRTUAL-MACHINE:
    type: tosca.nodes.MiCADO.Azure.Compute
    properties:
          resource_group: ADD_YOUR_RG_HERE (e.g. my-test)
          virtual_network: ADD_YOUR_VNET_HERE (e.g. my-test-vnet)
          subnet: ADD_YOUR_SUBNET_HERE (e.g. default)
          network_security_group: ADD_YOUR_NSG_HERE (e.g. my-test-nsg)
          size: ADD_YOUR_ID_HERE (e.g. Standard_B1ms)
          image: ADD_YOUR_IMAGE_HERE (e.g. 18.04.0-LTS or 2016-Datacenter)
          public_key: ADD_YOUR_MINIMUM_2048_KEY_HERE (e.g. ssh-rsa ASHFF...)
          public_ip: [OPTIONAL] BOOLEAN_ENABLE_PUBLIC_IP (e.g. true)

    interfaces:
      Terraform:
        create:

Under the **properties** section of a Azure virtual machine definition these
inputs are available.:

* **resource_group** specifies the name of the resource group in which
  the VM should exist.
* **virtual_network** specifies the virtual network associated with the VM.
* **subnet** specifies the subnet associated with the VM.
* **network_security_group** specifies the security settings for the VM.
* **vm_size** specifies the size of the VM.
* **image** specifies the name of the image.
* **public_ip [OPTIONAL]** Associate a public IP with the VM.
* **key_data** The public SSH key (minimum 2048-bit) to be associated with
  the instance.
  **Defining this property forces creation of a Linux VM. If it is not**
  **defined, a Windows VM will be created**

Under the **interfaces** section of a Azure virtual machine definition no
specific inputs are required, but **Terraform: create:** should be present

**Authentication** in Azure is supported by MiCADO in two ways:

  The first is by setting up a `Service Principal <https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html>`__
  and providing the required fields in *credentials-cloud-api.yml* during
  :ref:`cloud-credentials`

  The other option is by enabling a `System-Assigned Managed Identity <https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-portal-windows-vm#enable-system-assigned-managed-identity-during-creation-of-a-vm>`__
  on the **MiCADO Master VM** and then `modify access control <https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/howto-assign-access-portal#use-rbac-to-assign-a-managed-identity-access-to-another-resource>`__
  of the **current subscription** to assign the role of **Contributor** to
  the **MiCADO Master VM**

GCE
~~~

To instantiate MiCADO workers on a cloud through Google interface, please use
the template below. Currently, only **Terraform** has support for Azure,
so Terraform must be enabled as in :ref:`customize`, and the interface must
be set to Terraform as in the example below.

::

  YOUR-VIRTUAL-MACHINE:
    type: tosca.nodes.MiCADO.GCE.Compute
    properties:
          region: ADD_YOUR_ID_HERE (e.g. us-west1)
          zone: ADD_YOUR_ID_HERE (e.g. us-west1-a)
          project: ADD_YOUR_ID_HERE (e.g. PGCE)
          machine_type: ADD_YOUR_ID_HERE (e.g. n1-standard-2)
          image: ADD_YOUR_ID_HERE (e.g.  ubuntu-os-cloud/ubuntu-1804-lts)
          network: ADD_YOUR_ID_HERE (e.g. default)
          ssh-keys: ADD_YOUR_ID_HERE (e.g. ssh-rsa AAAB3N...)

    interfaces:
      Terraform:
        create:

Under the **properties** section of a GCE virtual machine definition these
inputs are available.:

* **project** is the project to manage the resources in.
* **image** specifies the image from which to initialize the VM disk.
* **region** is the region that the resources should be created in.
* **machine_type** specifies the type of machine to create.
* **zone** is the zone that the machine should be created in.
* **network** is the network to attach to the instance.
* **ssh-keys** sets the public SSH key to be associated with the instance.

Under the **interfaces** section of a GCE virtual machine definition no
specific inputs are required, but **Terraform: create:** should be present

**Authentication** in GCE is done using a service account key file in JSON
format. You can manage the key files using the Cloud Console. The steps to
retrieve the key file is as follows :

  * Open the **IAM & Admin** page in the Cloud Console.
  * Click **Select a project**, choose a project, and click **Open**.
  * In the left nav, click **Service accounts**.
  * Find the row of the service account that you want to create a key for.
    In that row, click the **More** button, and then click **Create key**.
  * Select a **Key type** and click **Create**.


Types
~~~~~

Through abstraction, it is possible to reference a
pre-defined type and simplify the description of a virtual machine. Currently
MiCADO supports these additional types for CloudSigma, but more can be written:

* **tosca.nodes.MiCADO.EC2.Compute.Terra** -
  Orchestrates with Terraform on eu-west-2, overwrite region_name
  under **properties** to change region
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
**and omitting capabilities metadata**

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

Monitoring Policy
-----------------

Metric collection is now disabled by default. The basic
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


Scaling Policy
--------------

Basic scaling
~~~~~~~~~~~~~

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

Optimiser-based scaling
~~~~~~~~~~~~~~~~~~~~~~~

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
  Optimiser must be enabled at deployment time. By default it is disabled. Once it is enabled and deployed, it can be driven through the scaling policy in subsections "constants" and "queries". Each parameter relating to the Optimiser must start with the "m_opt\_" string. In case no variable name with this prefix is found in any sections, Optimiser is not activated.

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

Network policy
--------------

There are six types of MiCADO network security policy.

* tosca.policies.Security.MiCADO.Network.Passthrough: Pass through network policy. Specifies no additional filtering, no application-level firewall on the nodes.

* tosca.policies.Security.MiCADO.Network.L7Proxy: Apply application-level firewall; can provide TLS control. No protocol enforcement.

::

    properties:
      encryption:
        type: boolean
        description: Specifies if encryption should be used
        required: true
      encryption_key:
        type: string
        description: The key file for TLS encryption as unencrypted .PEM
        required: false
      encryption_cert:
        type: string
        description: The cert file for TLS encryption as .PEM
        required: false
      encryption_offload:
        type: string
        description: Controls whether connection should be re-encrypted server side
        required: false
      encryption_cipher:
        type: string
        description: Specifies allowed ciphers client side during TLS handshake
        required: false

* tosca.policies.Security.MiCADO.Network.SmtpProxy: Enforce SMTP protocol, can provide TLS control.

::

    properties:
      relay_check:
        type: boolean
        description: Toggle relay checking
        required: true
      permit_percent_hack:
        type: boolean
        description: Allow the % symbol in the local part of an email address
        required: false
      error_soft:
        type: boolean
        description: Return a soft error when recipient filter does not match
        required: false
      relay_domains:
        type: list
        description: Domain mails are accepted for use postfix style lists
        required: false
      permit_exclamation_mark:
        type: boolean
        description: Allow the ! symbol in the local part of an email address
        required: false
      relay_domains_matcher_whitelist:
        type: list
        description: Domains mails accepted based on list of regex (precedence)
        required: false
      relay_domains_matcher_blacklist:
        type: list
        description: Domain mails rejected based on list of regular expressions
        required: false
      sender_matcher_whitelist:
        type: list
        description: Sender addresses accepted based on list of regex (precedence)
        required: false
      sender_matcher_blacklist:
        type: list
        description: Sender addresses rejected based on list of regex
        required: false
      recipient_matcher_whitelist:
        type: list
        description: Recipient addresses accepted based on list of regex (precedence)
        required: false
      recipient_matcher_blacklist:
        type: list
        description: Recipient addresses rejected based on list of regex
        required: false
      autodetect_domain_from:
        type: string
        description: Let Zorp autodetect firewall domain name and write to received line
        constraints:
          - valid_values: ["mailname", "fqdn"]
        required: false
      append_domain:
        type: string
        description: Domain to append to email addresses which do not specify a domain
        required: false
      permit_omission_of_angle_brackets:
        type: boolean
        description: Permit MAIL From and RCPT To params without normally required brackets
        required: false
      interval_transfer_noop:
        type: integer
        description: Interval between two NOOP commands sent to server while waiting for stack proxy results
        required: false
      resolve_host:
        type: boolean
        description: Resolve client host from IP address and write to received line
        required: false
      permit_long_responses:
        type: boolean
        description: Permit overly long responses as some MTAs include variable parts in responses
        required: false
      max_auth_request_length:
        type: integer
        description: Maximum allowed length of a request during SASL style authentication
        required: false
      max_response_length:
        type: integer
        description: Maximum allowed line length of server response
        required: false
      unconnected_response_code:
        type: integer
        description: Error code sent to client if connecting to server fails
        required: false
      add_received_header:
        type: boolean
        description: Add a received header into the email messages transferred by proxy
        required: false
      domain_name:
        type: string
        description: Fix a domain name into added receive line. add_received_header must be true
        required: false
      tls_passthrough:
        type: boolean
        description: Change to passthrough mode
        required: false
      extensions:
        type: list
        description: Allowed ESMTP extensions, indexed by extension verb
        required: false
      require_crlf:
        type: boolean
        description: Specify whether proxy should enforce valid CRLF line terminations
        required: false
      timeout:
        type: integer
        description: Timeout in ms - if no packet arrives, connection is dropped
        required: false
      max_request_length:
        type: integer
        description: Maximum allowed line length of client requests
        required: false
      permit_unknown_command:
        type: boolean
        description: Enable unknown commands
        required: false

* tosca.policies.Security.MiCADO.Network.HttpProxy: Enforce HTTP protocol, can provide TLS control.

::

    properties:
      max_keepalive_requests:
        type: integer
        description: Max number of requests allowed in a single session
        required: false
      permit_proxy_requests:
        type: boolean
        description: Allow proxy type requests in transparent mode
        required: false
      reset_on_close:
        type: boolean
        description: If connection is terminated without a proxy generated error, send an RST instead of a normal close
        required: false
      permit_unicode_url:
        type: boolean
        description: Allow unicode characters in URLs encoded as u'
        required: false
      permit_server_requests:
        type: boolean
        description: Allow server type requests in non transparent mode
        required: false
      max_hostname_length:
        type: integer
        description: Maximum allowed length of hostname field in URLs
        required: false
      parent_proxy:
        type: string
        description: Address or hostname of parent proxy to be connected
        required: false
      permit_ftp_over_http:
        type: boolean
        description: Allow processing FTP URLs in non transparent mode
        required: false
      parent_proxy_port:
        type: integer
        description: Port of parent proxy to be connected
        required: false
      permit_http09_responses:
        type: boolean
        description: Allow server responses to use limited HTTP 0 9 protocol
        required: false
      rewrite_host_header:
        type: boolean
        description: Rewrite host header in requests when URL redirection occurs
        required: false
      max_line_length:
        type: integer
        description: Maximum allowed length of lines in requests and responses
        required: false
      max_chunk_length:
        type: integer
        description: Maximum allowed length of a single chunk when using chunked transer encoding
        required: false
      strict_header_checking_action:
        type: string
        description: Specify Zorp action if non rfc or unknown header in communication
        constraints:
          - valid_values: ["accept", "drop", "abort"]
        required: false
      non_transparent_ports:
        type: list
        description: List of ports that non transparent requests may use
        required: false
      strict_header_checking:
        type: boolean
        description: Require RFC conformant HTTP headers
        required: false
      max_auth_time:
        type: integer
        description: Force new auth request from client browser after time in seconds
        required: false
      max_url_length:
        type: integer
        description: Maximum allowed length of URL in a request
        required: false
      timeout_request:
        type: integer
        description: Time to wait for a request to arrive from client
        required: false
      rerequest_attempts:
        type: integer
        description: Control number of attempts proxy takes to send request to server
        required: false
      error_status:
        type: integer
        description: On error, Zorp uses this as status code of HTTP response
        required: false
      keep_persistent:
        type: boolean
        description: Try to keep connection to client persistent, even if unsupported
        required: false
      error_files_directory:
        type: string
        description: Location of HTTP error messages
        required: false
      max_header_lines:
        type: integer
        description: Maximum number of eader lines allowed in requests and responses
        required: false
      use_canonicalized_urls:
        type: boolean
        description: Enable canonicalization - converts URLs to canonical form
        required: false
      max_body_length:
        type: integer
        description: Maximum allowed length of HTTP request or response body
        required: false
      require_host_header:
        type: boolean
        description: Require presence of host header
        required: false
      buffer_size:
        type: integer
        description: Size of I O buffer used to transfer entity bodies
        required: false
      permitted_responses:
        type: list
        description: Normative policy hash for HTTP responses indexed by HTTP method and response code
        entry_schema:
          description: dictionary (string/int)
          type: map
        required: false
      transparent_mode:
        type: boolean
        description: Enable transparent mode for the proxy
        required: false
      permit_null_response:
        type: boolean
        description: Permit RFC incompliant responses with headers not terminated by CRLF, and not containing entity body
        required: false
      language:
        type: string
        description: Specify language of HTTP error pages displayed to client
        required: false
        default: English
      error_silent:
        type: boolean
        description: Turns off verbose error reporting to HTTP client, making firewall fingerprinting more difficult
        required: false
      permitted_requests:
        type: list
        description: List of permitted HTTP methods indexed by verb
        required: false
      use_default_port_in_transparent_mode:
        type: boolean
        description: Enable use of default port in transparent mode
        required: false
      timeout_response:
        type: integer
        description: Time to wait for the HTTP status line to arrive from the server
        required: false
      permit_invalid_hex_escape:
        type: boolean
        description: Allow invalid hexadecimal escaping in URLs
        required: false
      auth_cache_time:
        type: integer
        description: Caching authentication information time in seconds
        required: false
      timeout:
        type: integer
        description: General I O timeout in ms
        required: false
      default_port:
        type: integer
        description: Used in non transparent mode when URL does not contain a port number
        required: false
        default: 80

* tosca.policies.Security.MiCADO.Network.HttpURIFilterProxy: Enforce HTTP protocol with regex URL filtering capabilities

::

    properties:
      matcher_whitelist:
        type: list
        description: List of regex determining permitted access to a URL (precedence)
        required: true
      matcher_blacklist:
        type: list
        description: List of regex determining prohibited access to a URL
        required: true

* tosca.policies.Security.MiCADO.Network.HttpWebdavProxy: Enforce HTTP protocol with request methods for WebDAV.

This proxy has no additional properties.

Secret policy
-------------

There is a way to define application-level secrets in the MiCADO application description. These secrets are distributed by kubernetes.

::

  tosca.policies.Security.MiCADO.Secret.KubernetesSecretDistribution:
    derived_from: tosca.policies.Root
    description: distributes secrets to services
    properties:
      file_secrets:
        type: map
      text_secrets:
        type: map
