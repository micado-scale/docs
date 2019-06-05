.. _applicationdescription:

Application description
***********************

MiCADO executes applications described by the Application Descriptions following the TOSCA format. This section details the structure of the application description.

Application description has four main sections:

* **tosca_definitions_version**: ``tosca_simple_yaml_1_0``.
* **imports**: a list of urls pointing to custom TOSCA types. The default url points to the custom types defined for MiCADO. Please, do not modify this url.
* **repositories**: docker repositories with their addresses.
* **topology_template**: the goal of the application description is to define 1) kubernetes deployments (of docker containers), 2) virtual machine (under the **node_templates** section) and 3) the scaling policy under the **policies** subsection. These sections will be detailed in subsections below.

Here is an example for the structure of the MiCADO application description:

::

   tosca_definitions_version: tosca_simple_yaml_1_0

   imports:
     - https://raw.githubusercontent.com/micado-scale/tosca/v0.x.2/micado_types.yaml

   repositories:
     docker_hub: https://hub.docker.com/

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
       
       YOUR-OTHER-KUBERNETES-APP:
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
           host:
             properties:
               ...

       YOUR-OTHER-VIRTUAL-MACHINE:
         type: tosca.nodes.MiCADO.<CLOUD_API_TYPE>.Compute
         properties:
           ...
         interfaces:
           ...
         capabilities:
           host:
             properties:
               ...

     outputs:
       ports:
         value: { get_attribute: [ YOUR-KUBERNETES-APP, port ]}

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

Specification of Docker containers (to be orchestrated by Kubernetes)
=====================================================================

**NOTE** Kubernetes does not allow for underscores in any resource names (read: TOSCA node names). Names must also begin and end with an alphanumeric.

Under the node_templates section you can define one or more Docker containers and choose to orchestrate them with Kubernetes 
(see **YOUR-KUBERNETES-APP**). Each app is described as a separate node with its own definition consisting of 
four main parts: type, properties, artifacts and interfaces.

The **type** keyword for Docker containers must always be ``tosca.nodes.MiCADO.Container.Application.Docker``

The **properties** section will contain the options specific to the Docker container runtime

The **artifacts** section must define the Docker image (see **YOUR_DOCKER_IMAGE**)

The **interfaces** section tells MiCADO how to orchestrate the container. 

The *create* field *inputs* will override the **workload** metadata & spec of a bare Kubernetes Deployment manifest. 

The *configure* field *inputs* will override the **pod** metadata & spec of that workload.

**A stripped back definition of a node_template looks like this:**

::

   topology_template:
     node_templates:
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
            repository: docker_hub
         requirements:
         - host:
             node: YOUR-VIRTUAL-MACHINE
         interfaces:
           Kubernetes:
             create:
               implementation: image
               inputs:
                 ...
             configure:
               inputs:
                 ...
     outputs:
        ports:
          value: { get_attribute: [ YOUR-KUBERNETES-APP, port ]}

The fields under the **properties** section of the Kubernetes app are a collection of options specific to all iterations
of Docker containers. The translator understands both Docker-Compose style naming and Kubernetes style naming, though 
the Kubernetes style is recommended. You can find additional information about properties in the
`translator documentation <https://github.com/jaydesl/TOSCAKubed/blob/master/README.md>`__. These  properties will be translated 
into Kubernetes manifests on deployment.

Under the **properties** section of an app (see **YOUR-KUBERNETES-APP**) here are a few common keywords.:

* **name**: name for the container (defaults to the TOSCA node name)
* **command**: override the default command line expression to be executed by the container.
* **args**: override the default entrypoint of container.
* **env**: list of *name:* & *value:* of all required environment variables.
* **resource.requests.cpu**: CPU reservation, should be set 100m lower than max (900m == 1000m)
* **ports**: list of published ports to the host machine, you can specify these keywords in the style of a `Kubernetes Service <https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.13/#service-v1-core>`__

  * **targetPort**: the port to target (assumes port if not specified)
  * **port**: the port to publish (assumes targetPort if not specified)
  * **name**: the name of this port in the service (will be generated if not specified)
  * **protocol**: the protocol for the port (defaults to: TCP)
  * **nodePort**: the port (30000-32767) to expose on the host (this will create a nodePort Service unless type is explicitly set below)
  * **type**: the type of service for this port (defaults to: ClusterIP except if nodePort is defined above) 
  * **clusterIP**: the desired (internal) IP (10.0.0.0/24) for this service (defaults to next available)
  * **metadata**: service metadata, giving the option to set a name for the service. Explicit naming can be used to group different ports together (default grouping is by type)


Under the **artifacts** section you can define the docker image for the
kubernetes app. Three fields must be defined:

* **type**: ``tosca.artifacts.Deployment.Image.Container.Docker``
* **file**: docker image for the kubernetes app (e.g. sztakilpds/cqueue_frontend:latest )
* **repository**: name of the repository where the image is located. The name used here (e.g. docker_hub), must be defined at the top of the description under the **repositories** section.

Under the **requirements** section you can define the virtual machine you want to host this particular app, 
restricting the container to run **only** on that VM. If you do not provide a host requirement, the container will 
run on any possible virtual machine. You can also attach a volume to this app - the definition of volumes can be 
found in the next section. Requirements takes a list of map objects:

* **host:**
    **node:** name of your virtual machine as defined under node_templates

* **volume:**

    **node:** name of your volume as defined under node_templates

    **relationship:**

        **type:** tosca.relationships.AttachesTo

        **properties:**
            **location:** path on container

Under the **interfaces** section you can define orchestrator specific options, here we use the key **Kubernetes:**

* **create**: *this key tells MiCADO to create a workload (Deployment/DaemonSet/Job/Pod etc...) for this container*


    **implementation**: *this should always point to your image artifact*

    **inputs**: *top-level workload and workload spec options follow here... Some examples, see* `translator documentation <https://github.com/jaydesl/TOSCAKubed/blob/master/README.md>`__
  
       **kind:** overwrite the workload type (defaults to Deployment)
      
       **strategy.type:** change to Recreate to kill pods then update (defaults to RollingUpdate)

* **configure**: *this key configures the Pod for this workload*

    **inputs**: `PodTemplateSpec <https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.13/#podspec-v1-core>`__ options follow here... For example
  
     **restartPolicy:** change the restart policy (defaults to Always)

**A word on networking in Kubernetes**

Kubernetes networking is inherently different to the approach taken by Docker/Swarm. 
This is a complex subject which is worth a read: https://kubernetes.io/docs/concepts/cluster-administration/networking/ . 
Since every pod gets its own IP, which any pod can by default use to communicate with any other pod, this means there 
is no network to explicitly define. If the **ports** keyword is defined in the definition above, pods can reach each other over CoreDNS via their hostname (container name).

Under the **outputs** section (this key is **NOT** nested within *node_templates*) 
you can define an output to retrieve from Kubernetes via the adaptor. Currently, only port info is obtainable.

Specification of Volumes
====================================
Volumes are defined at the same level as virtual machines and containers, and are then connected to containers using the 
**requirements** notation provided above in the container spec.

Under the **properties** section of a volume (see **YOUR-VOLUME**) you should define a name.:
* **name**: name for the volume

Under the **interfaces** section you can define orchestrator specific options, here we use the key **Kubernetes:**

* **create**: *this key tells MiCADO to create a persistent volume and claim*

  * **inputs**: volume specific spec options go here... these are two popular examples, see `Kubernetes Documentation <https://kubernetes.io/docs/concepts/storage/volumes/>`__ for more
   
    * **nfs:**
        **server:** IP of NFS server
        
        **path:** path on NFS share

      **OR**

    * **hostPath:**
        **path:** path on host

Specification of the Virtual Machine
====================================

The collection of docker containers (kubernetes applications) specified in the previous section is orchestrated by Kubernetes. This section introduces how the parameters of the virtual machine can be configured which will host the Kubernetes worker node. During operation MiCADO will instantiate as many virtual machines with the parameters defined here as required during scaling. MiCADO currently supports four different cloud interfaces: CloudSigma, CloudBroker, EC2, Nova. MiCADO supports multiple virtual machine "sets" which can be restricted and host only specific containers (defined in the requirements section of the container specification). At the moment multi-cloud support is in alpha stage, so only certain combinations of different cloud service providers will work.

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
-------

The **capabilities** sections for all virtual machine definitions that follow are identical and are **ENTIRELY OPTIONAL**. They are filled with metadata to support human readability.:

*  **num_cpus** under *host* is a readable string specifying clock speed of the instance type
*  **mem_size** under *host* is a readable string specifying RAM of the instance type
*  **type** under *os* is a readable string specifying the operating system type of the image
*  **distribution** under *os* is a readable string specifying the OS distro of the image
*  **version** under *os* is a readable string specifying the OS version of the image

The **interfaces** section of all virtual machine definitions that follow are **REQUIRED**, and allow you to provide orchestrator specific inputs, in the examples below we use **Occopus**.

* **create**: *this key tells MiCADO to create the VM using Occopus*

  * **inputs**: Specific settings for Occopus follow here
  
    * **interface_cloud:** tells Occopus which cloud to interface with
    * **endpoint_cloud:** tells Occopus the endpoint API of the cloud



CloudSigma
----------

To instantiate MiCADO workers on CloudSigma, please use the template below. MiCADO **requires** num_cpus, mem_size, vnc_password, libdrive_id, public_key_id and firewall_policy to instantiate VM on *CloudSigma*.

::

   topology_template:
     node_templates:
       worker_node:
         type: tosca.nodes.MiCADO.Occopus.CloudSigma.Compute
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
-----------

To instantiate MiCADO workers on CloudBroker, please use the template below. MiCADO **requires** deployment_id and instance_type_id to instantiate a VM on *CloudBroker*.

::

   topology_template:
     node_templates:
       worker_node:
         type: tosca.nodes.MiCADO.Occopus.CloudBroker.Compute
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
---

To instantiate MiCADO workers on a cloud through EC2 interface, please use the template below. MiCADO **requires** region_name, image_id and instance_type to instantiate a VM through *EC2*.

::

   topology_template:
     node_templates:
       worker_node:
         type: tosca.nodes.MiCADO.Occopus.EC2.Compute
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
----

To instantiate MiCADO workers on a cloud through Nova interface, please use the template below. MiCADO **requires** image_id flavor_name, project_id and network_id to instantiate a VM through *Nova*.

::

   topology_template:
     node_templates:
       worker_node:
         type: tosca.nodes.MiCADO.Occopus.Nova.Compute
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

Description of the scaling policy
=================================

To utilize the autoscaling functionality of MiCADO, scaling policies can be defined on virtual machine and on the application level. Scaling policies can be listed under the **policies** section. Each **scalability** subsection must have the **type** set to the value of ``tosca.policies.Scaling.MiCADO`` and must be linked to a node defined under **node_template**. The link can be implemented by specifying the name of the node under the **targets** subsection. You can attach different policies to different containers or virtual machines, though a new policy should exist for each. The details of the scaling policy can be defined under the **properties** subsection. The structure of the **policies** section can be seen below.

::

   topology_template:
     node_templates:
       YOUR-KUBERNETES-APP:
         type: tosca.nodes.MiCADO.Container.Application.Docker
         ...
       ...
       YOUR-OTHER-KUBERNETES-APP:
         type: tosca.nodes.MiCADO.Container.Application.Docker
         ...
       YOUR-VIRTUAL-MACHINE:
         type: tosca.nodes.MiCADO.Occopus.<CLOUD_API_TYPE>.Compute
         ...
       YOUR-OTHER-VIRTUAL-MACHINE:
         type: tosca.nodes.MiCADO.Occopus.<CLOUD_API_TYPE>.Compute
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

The scaling policies are evaluated periodically. In every turn, the virtual machine level scaling is evaluated, followed by the evaluation of each scaling policies belonging to kubernetes-deployed applications.

The **properties** subsection defines the scaling policy itself. For monitoring purposes, MiCADO integrates the Prometheus monitoring tool with two built-in exporters on each worker node: Node exporter (to collect data on nodes) and CAdvisor (to collect data on containers). Based on Prometheus, any monitored information can be extracted using the Prometheus query language and the returned value can be associated to a user-defined variable. Once variables are updated, scaling rule is evaluated. It can be specified by a short Python code which can refer to the monitored information. The structure of the scaling policy can be seen below.

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
             THELOAD: 'Prometheus query expression'
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
* **queries** contains the list of Prometheus query expressions to be executed and their variable name associated (see ``THELOAD`` above)
* **alerts** subsection enables the utilisation of the alerting system of Prometheus. Each alert defined here is registered under Prometheus and fired alerts are represented with a variable of their name set to True during the evaluation of the scaling rule (see ``myalert`` above).
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
    - m_container_count: the target number of containers for the service the evaluation belongs to
    - m_time_since_node_count_changed: time in seconds elapsed since the number of nodes changed

  - In a scaling rule belonging to the virtual machine, the name of the variable to be updated is ``m_node_count``; as an effect the number stored in this variable will be set as target instance number for the virtual machines.
  - In a scaling rule belonging to a kubernetes deployment, the name of the variable to be set is ``m_container_count``; as an effect the number stored in this variable will be set as target instance number for the kubernetes service.

For further examples, inspect the scaling policies of the demo examples detailed in the next section.
