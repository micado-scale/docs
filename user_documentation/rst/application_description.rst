.. _applicationdescription:

Application description
***********************

MiCADO executes applications described by the Application Descriptions following the TOSCA format. This section details the structure of the application description.

Application description has four main sections:

* **tosca_definitions_version**: ``tosca_simple_yaml_1_0``.
* **imports**: a list of urls pointing to custom TOSCA types. The default url points to the custom types defined for MiCADO. Please, do not modify this url.
* **repositories**: docker repositories with their addresses.
* **topology_template**: the main part of the application description to define 1) kubernetes deployments (of docker containers), 2) virtual machine (under the **node_templates** section) and 3) the scaling policy under the **policies** subsection. These sections will be detailed in subsections below.

Here is an overview example for the structure of the MiCADO application
description:

::

   tosca_definitions_version: tosca_simple_yaml_1_0

   imports:
     - https://raw.githubusercontent.com/micado-scale/tosca/v0.6.0/micado_types.yaml

   repositories:
     docker_hub: https://hub.docker.com/

   topology_template:
     node_templates:
       YOUR_KUBERNETES_APP:
         type: tosca.nodes.MiCADO.Container.Application.Docker
         properties:
           ...
         artifacts:
           ...
       ...
       YOUR_OTHER_KUBERNETES_APP:
         type: tosca.nodes.MiCADO.Container.Application.Docker
         properties:
           ...
         artifacts:
           ...

       YOUR_VIRTUAL_MACHINE:
         type: tosca.nodes.MiCADO.Occopus.<CLOUD_API_TYPE>.Compute
         properties:
           cloud:
             interface_cloud: ...
             endpoint_cloud: ...
         capabilities:
           host:
             properties:
               ...

     policies:
     - scalability:
       type: tosca.policies.Scaling.MiCADO
       targets: [ YOUR_VIRTUAL_MACHINE ]
       properties:
         ...
     - scalability:
       type: tosca.policies.Scaling.MiCADO
       targets: [ YOUR_KUBERNETES_APP ]
       properties:
         ...
     - scalability:
       type: tosca.policies.Scaling.MiCADO
       targets: [ YOUR_OTHER_KUBERNETES_APP ]
       properties:
         ...

Specification of Kubernetes Deployments (as Docker containers)
==============================================================

Under the node_templates section you can define one or more apps to create a Kubernetes Deployment (using Docker compose nomenclature) (see **YOUR_KUBERNETES_APP**). Each app within the Kubernetes deployment gets its own definition consisting of three main parts: type, properties and artifacts. The value of the **type** keyword for the Kubernetes Deployment of a Docker container must always be ``tosca.nodes.MiCADO.Container.Application.Docker``. The **properties** section will contain most of the setting of the app to be deployed using Kubernetes. Under the **artifacts** section the Docker image (see **YOUR_DOCKER_IMAGE**) must be defined.

::

   topology_template:
     node_templates:
       YOUR_KUBERNETES_APP:
         type: tosca.nodes.MiCADO.Container.Application.Docker
         properties:
            ...
         artifacts:
          image:
            type: tosca.artifacts.Deployment.Image.Container.Docker
            file: YOUR_DOCKER_IMAGE
            repository: docker_hub

The fields under the **properties** section of the Kubernetes app are derived from a docker-compose file and converted using Kompose. You can find additional information about the properties in the `docker compose documentation <https://docs.docker.com/compose/compose-file/#service-configuration-reference>` and see what `Kompose supports here <http://kompose.io/conversion/>`. The syntax of the property values is currently the same as in docker-compose 
file. The Compose properties will be translated into Kubernetes specs on deployment.

Under the **properties** section of an app (see **YOUR_KUBERNETES_APP**) you can specify the following keywords.:

* **command**: command line expression to be executed by the container.
* **deploy**: Orchestrated deployment options. CPU reservations should be set 0.1 lower than in Swarm (0.9 == 1.0)
* **entrypoint**: override the default entrypoint of container.
* **environment**: map of all required environment variables.
* **expose**: expose ports without publishing them to the host machine.
* **volumes**: list of bind mount (host-container) volumes for the service in the format */source/etc/data:/target/etc/data*
* **ports**: list of published ports to the host machine. **Unlike Docker** this does not make the container accessible from the outside.
* **labels**: map of metadata like Docker labels and/or Kubernetes instructions (see NOTE).

*NOTE*

* **labels** can also be used to pass instructions to Kubernetes (full list: http://kompose.io/user-guide/#labels) 
**kompose.service.type: 'nodeport'** will make the container accessible at *<worker_node_ip>:port* where port can be found on the Kubernetes Dashboard under *Discovery and load balancing > Services > my_app > Internal endpoints*

Under the **artifacts** section you can define the docker image for the
kubernetes app. Three fields must be defined:

* **type**: ``tosca.artifacts.Deployment.Image.Container.Docker``
* **file**: docker image for the kubernetes app (e.g. sztakilpds/cqueue_frontend:latest )
* **repository**: name of the repository where the image is located. The name used here (e.g. docker_hub), must be defined at the top of the description under the **repositories** section.

Kubernetes networking is inherently different to the approach taken by Docker. This is a complex subject which is worth a read: https://kubernetes.io/docs/concepts/cluster-administration/networking/

Since every pod gets its own IP, which any pod can by default use to communicate with any other pod, this means there is no network to explicitly define. If **ports** is defined in the definition above, pods can reach each other over CoreDNS via their hostname (container name).

Specification of the Virtual Machine
====================================

The collection of docker containers (kubernetes applications) specified in the previous section is orchestrated by Kubernetes. This section introduces how the parameters of the virtual machine can be configured which will be hosts the Kubernetes worker node. During operation MiCADO will instantiate as many virtual machines with the parameters defined here as required during scaling. MiCADO currently supports four different cloud interfaces: CloudSigma, CloudBroker, EC2, Nova. The following ports and protocols should be enabled on the virtual machine:

::

   ICMP
   TCP: 22,2377,7946,8300,8301,8302,8500,8600,9100,9200
   UDP: 4789,7946,8301,8302,8600

The following subsections details how to configure them.

CloudSigma
----------

To instantiate MiCADO workers on CloudSigma, please use the template below. MiCADO **requires** num_cpus, mem_size, vnc_password, libdrive_id and public_key_id to instantiate VM on *CloudSigma*.

::

   topology_template:
     node_templates:
       worker_node:
         type: tosca.nodes.MiCADO.Occopus.CloudSigma.Compute
         properties:
           cloud:
             interface_cloud: cloudsigma
             endpoint_cloud: ADD_YOUR_ENDPOINT (e.g for cloudsigma https://zrh.cloudsigma.com/api/2.0 )
         capabilities:
           host:
             properties:
               num_cpus: ADD_NUM_CPUS_FREQ (e.g. 4096)
               mem_size: ADD_MEM_SIZE (e.g. 4294967296)
               vnc_password: ADD_YOUR_PW (e.g. secret)
               libdrive_id: ADD_YOUR_ID_HERE (eg. 87ce928e-e0bc-4cab-9502-514e523783e3)
               public_key_id: ADD_YOUR_ID_HERE (e.g. d7c0f1ee-40df-4029-8d95-ec35b34dae1e)
               firewall_policy: ADD_YOUR_ID_HERE (e.g. fd97e326-83c8-44d8-90f7-0a19110f3c9d)

*  **num_cpu** is the speed of CPU (e.g. 4096) in terms of MHz of your VM to be instantiated. The CPU frequency required to be between 250 and 100000
*  **mem_size** is the amount of RAM (e.g. 4294967296) in terms of bytes to be allocated for your VM. The memory required to be between 268435456 and 137438953472
*  **vnc_password** set the password for your VNC session (e.g. secret).
*  **libdrive_id** is the image id (e.g. 87ce928e-e0bc-4cab-9502-514e523783e3) on your CloudSigma cloud. Select an image containing a base os installation with cloud-init support!
*  **public_key_id** specifies the keypairs (e.g. d7c0f1ee-40df-4029-8d95-ec35b34dae1e) to be assigned to your VM.
*  **firewall_policy** optionally specifies network policies (you can define multiple security groups in the form of a list, e.g. fd97e326-83c8-44d8-90f7-0a19110f3c9d) of your VM.

CloudBroker
-----------

To instantiate MiCADO workers on CloudBroker, please use the template below. MiCADO **requires** deployment_id and instance_type_id to instantiate a VM on *CloudBroker*.

::

   topology_template:
     node_templates:
       worker_node:
         type: tosca.nodes.MiCADO.Occopus.CloudBroker.Compute
         properties:
           cloud:
             interface_cloud: cloudbroker
             endpoint_cloud: ADD_YOUR_ENDPOINT (e.g https://cola-prototype.cloudbroker.com )
         capabilities:
           host:
             properties:
               deployment_id: ADD_YOUR_ID_HERE (e.g. e7491688-599d-4344-95ef-aff79a60890e)
               instance_type_id: ADD_YOUR_ID_HERE (e.g. 9b2028be-9287-4bf6-bbfe-bcbc92f065c0)
               key_pair_id: ADD_YOUR_ID_HERE (e.g. d865f75f-d32b-4444-9fbb-3332bcedeb75)
               opened_port: ADD_YOUR_PORTS_HERE (e.g. '22,2377,7946,8300,8301,8302,8500,8600,9100,9200,4789')

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
           cloud:
             interface_cloud: ec2
             endpoint_cloud: ADD_YOUR_ENDPOINT (e.g https://ec2.eu-west-1.amazonaws.com )
         capabilities:
           host:
             properties:
               region_name: ADD_YOUR_REGION_NAME_HERE (e.g. eu-west-1)
               image_id: ADD_YOUR_ID_HERE (e.g. ami-12345678)
               instance_type: ADD_YOUR_INSTANCE_TYPE_HERE (e.g. t1.small)

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
           cloud:
             interface_cloud: nova
             endpoint_cloud: ADD_YOUR_ENDPOINT (e.g https://sztaki.cloud.mta.hu:5000/v3)
         capabilities:
           host:
             properties:
               image_id: ADD_YOUR_ID_HERE (e.g. d4f4e496-031a-4f49-b034-f8dafe28e01c)
               flavor_name: ADD_YOUR_ID_HERE (e.g. 3)
               project_id: ADD_YOUR_ID_HERE (e.g. a678d20e71cb4b9f812a31e5f3eb63b0)
               network_id: ADD_YOUR_ID_HERE (e.g. 3fd4c62d-5fbe-4bd9-9a9f-c161dabeefde)
               key_name: ADD_YOUR_KEY_HERE (e.g. keyname)
               security_groups:
                 - ADD_YOUR_ID_HERE (e.g. d509348f-21f1-4723-9475-0cf749e05c33)

*  **project_id** is the id of project you would like to use on your target Nova cloud.
*  **image_id** is the image id on your Nova cloud. Select an image containing a base os installation with cloud-init support!
*  **flavor_name** is the name of flavor to be instantiated on your Nova cloud.
*  **server_name** optionally defines the hostname of VM (e.g.:”helloworld”).
*  **key_name** optionally sets the name of the keypair to be associated to the instance. Keypair name must be defined on the target nova cloud before launching the VM.
*  **security_groups** optionally specify security settings (you can define multiple security groups in the form of a list) for your VM.
*  **network_id** is the id of the network you would like to use on your target Nova cloud.

Description of the scaling policy
=================================

To utilize the autoscaling functionality of MiCADO, scaling policies can be defined on virtual machine and on the application level. Scaling policies can be listed under the **policies** section. Each **scalability** subsection must have the **type** set to the value of ``tosca.policies.Scaling.MiCADO`` and must be linked to a node defined under **node_template**. The link can be implemented by specifying the name of the node under the **targets** subsection. The details of the scaling policy can be defined under the **properties** subsection. The structure of the **policies** section can be seen below.

::

   topology_template:
     node_templates:
       YOUR_KUBERNETES_APP:
         type: tosca.nodes.MiCADO.Container.Application.Docker
         ...
       ...
       YOUR_OTHER_KUBERNETES_APP:
         type: tosca.nodes.MiCADO.Container.Application.Docker
         ...
       YOUR_VIRTUAL_MACHINE:
         type: tosca.nodes.MiCADO.Occopus.<CLOUD_API_TYPE>.Compute
         ...

     policies:
     - scalability:
       type: tosca.policies.Scaling.MiCADO
       targets: [ YOUR_VIRTUAL_MACHINE ]
       properties:
         ...
     - scalability:
       type: tosca.policies.Scaling.MiCADO
       targets: [ YOUR_KUBERNETES_APP ]
       properties:
         ...
     - scalability:
       type: tosca.policies.Scaling.MiCADO
       targets: [ YOUR_OTHER_KUBERNETES_APP ]
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

* **sources** supports the dynamic attachment of an external exporter by specifying a list endpoints of exporters (see example above). Each item found under this subsection is configured under Prometheus to start collecting the information provided/exported by the exporters. Once done, the values of the parameters provided by the exporters become available. **NEW** MiCADO now supports Kubernetes service discovery - to define such a source, simply pass the name of the app as defined in TOSCA and do not specify any port number
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
