MiCADO - autoscaling framework for Docker services on Cloud
###########################################################

This software is developed by the `COLA project <https://project-cola.eu/>`__.

Introduction
************

MiCADO is an auto-scaling framework for Docker applications. It supports autoscaling at two levels. At virtual machine (VM) level, a built-in Docker Swarm cluster is dynamically extended or reduced by adding/removing cloud virtual machines. At docker service level, the number of replicas implementing a Docker Service can be increased/decreased.

MiCADO requires a TOSCA based Application Description to be submitted containing three sections: 1) the definition of the interconnected Docker services, 2) the specification of the virtual machine and 3) the implementation of scaling policy for both scaling levels. The format of the Application Description for MiCADO is detailed later.

To use MiCADO, first the MiCADO core services must be deployed on a virtual machine (called MiCADO Master) by an Ansible playbook. MiCADO Master contains Docker engine (configured as Swarm manager), Occopus (to scale VMs), Prometheus (for monitoring), Policy Keeper (to perform decision on scaling) and Submitter (to provide submission endpoint) microservices to realize the autoscaling control loops. During operation MiCADO workers (realised on new VMs) are instantiated on demand which deploy Prometheus Node Exporter, CAdvisor and Docker engine through contextualisation. The Docker engine of the newly instantiated MiCADO workers joins the Swarm manager on the MiCADO Master.

In the current release, the status of the system can be inspected through the following ways: REST API provides interface for submission, update and list functionalities over applications. Dashboard provides three graphical view to inspect the VMs and Docker services. They are Docker Visualizer, Grafana and Prometheus. Finally, advanced users may find the logs of the MiCADO core services useful on MiCADO master.

.. toctree::
   :maxdepth: 2
   :caption: User Documentation

   deployment
   dashboard
   rest_api
   application_description
   tutorials
   release_notes
