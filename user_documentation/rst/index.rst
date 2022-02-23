MiCADO - autoscaling framework for Kubernetes Deployments in the Cloud
######################################################################

This software is developed by the `COLA project <https://project-cola.eu/>`__ and is hosted at the `MiCADO-scale github repository <https://github.com/micado-scale>`__. Please, visit the `MiCADO homepage <https://www.micado-scale.eu/>`__ for general information about the product.

Introduction
************

MiCADO is an auto-scaling framework for Docker containers, orchestrated by Kubernetes. It supports autoscaling at two levels. At virtual machine (VM) level, a built-in Kubernetes cluster is dynamically extended or reduced by adding/removing cloud virtual machines. At Kubernetes level, the number of replicas tied to a specific Kubernetes Deployment can be increased/decreased.

MiCADO requires a TOSCA-based Application Description Template to be submitted containing three sections:

1. the definition of the individual applications making up a Kubernetes Deployment,
2. the specification of the virtual machine and
3. the implementation of policies for scaling and monitoring both levels of the application.

The format of the Application Description Template for MiCADO is detailed later.

To use MiCADO, first the MiCADO core services must be deployed on a virtual machine (called MiCADO Master) by an Ansible playbook. MiCADO Master is configured as the Kubernetes Master Node and has installed the Docker Engine, Occopus and Terraform (to scale VMs), Prometheus (for monitoring), Policy Keeper (to perform decision on scaling) and Submitter (to provide submission endpoint) microservices to realize the autoscaling control loops. During operation MiCADO workers (realised on new VMs) are instantiated on demand which deploy Prometheus Node Exporter and CAdvisor as Kubernetes DaemonSets and the Docker engine through contextualisation. The newly instantiated MiCADO workers join the Kubernetes cluster managed by the MiCADO Master.

In the current release, the status of the system can be inspected through the following ways: REST API provides interface for submission, update and list functionalities over applications. Dashboard provides three graphical view to inspect the VMs and Kubernetes Deployments. They are the Kubernetes Dashboard, Grafana and Prometheus. Finally, advanced users may find the logs of the MiCADO core services useful in the Kubernetes Dashboard under the ``micado-system`` and ``micado-worker`` namespaces, or directly on the MiCADO master.

.. toctree::
   :maxdepth: 2
   :caption: User Documentation

   deployment
   dashboard
   RESTful API <https://micado-scale.github.io/component_submitter/swagger.html>
   application_description
   tutorials
   MiCADO Client Library <https://micado-scale.github.io/micado-client>
   release_notes
   whats_new
