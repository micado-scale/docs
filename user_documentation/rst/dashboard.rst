.. _dashboard:

Dashboard
*********

MiCADO has a simple dashboard that collects web-based user interfaces into a single view. To access the Dashboard, visit ``https://[IP]:[PORT]``, where

* [IP] is the ip address of MiCADO master, the virtual machine you have launched in Step 4 of :ref:`deployment`

* [PORT] is the port number configured during Step 4 of :ref:`deployment`, its value is held by the ``web_listening_port`` variable specified in the ``micado-master.yml`` ansible file.

The following webpages are currently exposed:

* Kubernetes Dashboard: A read-only instance of the Kubernetes WebUI providing a full overview of the infrastructure. Simply *SKIP* the authentication pop-up to gain read-only access to the dashboard.
* Grafana: graphically visualize the resources (nodes, containers) in time. After deploying your application, you can select the service whose metrics you want using the 'Service' drop down running above the graphs area.
* Prometheus: monitoring subsystem. Recommended for developers, experts.
