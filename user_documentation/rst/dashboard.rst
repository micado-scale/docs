.. _dashboard:

Dashboard
*********

MiCADO has a simple dashboard that collects web-based user interfaces into a single view. To access the Dashboard, visit ``https://[IP]:[port]``. This port number is configured during initial setup of the MiCADO master *(Docs > Deployment > Installation > Step 5 > web_listening_port)* and defaults to port 443.

The following webpages are currently exposed:

* Docker visualizer: it graphically visualizes the Swarm nodes and the containers running on them.
* Grafana: graphically visualize the resources (nodes, containers) in time.
* Prometheus: monitoring subsystem. Recommended for developers, experts.
