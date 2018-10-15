.. _dashboard:

Dashboard
*********

MiCADO has a simple dashboard that collects web-based user interfaces into a single view. To access the Dashboard, visit ``https://[IP]:[PORT]``, where 

* [IP] is the ip address of MiCADO master, the virtual machine you have launched in Step 4 of :ref:`deployment`

* [PORT] is the port number configured during Step 4 of :ref:`deployment`, its value is held by the ``web_listening_port`` variable specified in the ``micado-master.yml`` ansible file. 

The following webpages are currently exposed:

* Docker visualizer: it graphically visualizes the Swarm nodes and the containers running on them.
* Grafana: graphically visualize the resources (nodes, containers) in time.
* Prometheus: monitoring subsystem. Recommended for developers, experts.
