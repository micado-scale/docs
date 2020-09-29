Release Notes
*************

| **Changelog since v0.5.x of MiCADO**
| See more detailed notes about upgrading in :ref:`whatsnew`

v0.9.1 (30 September 2020)
=====================

- Add support for Oracle Cloud Infrastructure
- Add support for Ubuntu 20.04 LTS
- Improve RESTful nature of Submitter with v2.0 API
- Base component images on ``alpine`` for a smaller footprint
- Bump Kubernetes to v1.19
- Support TOSCA v1.2 template files
- Refactor custom TOSCA type definitions
- Refactor Submitter parsing modules to improve parsing times
- Refactor KubernetesAdaptor for more customisable resources
- Improve validation of translated Kubernetes manifests
- Support config_drive flag in OpenStack (Terraform only)
- Port PolicyKeeper to Python3
- Increase timeout for MiCADO component deployment (for slower machines)
- Increase timeout for inactive worker node removal (for poor networks)
- Reduce Prometheus default scrape interval (for custom exporters)
- Add ``mode`` to Ansible tasks for CVE-2020-1736
- Include hostname and IP as SANs in self-signed certs
- Fix: enable secret distribution via ADT policy


v0.9.0 (9 April 2020)
=====================

- Refactor playbook tasks to be more component-specific
- Add playbook tasks for configuring and installing Terraform
- Use the Ansible *k8s module* for managing Kubernetes resources
- Optimise cloud-init scripts by reducing *apt-get update*
- Fix Master-Worker Ubuntu mismatch bug
- Handle undefined credential file path
- Store credential data in Kubernetes Secrets
- Support updates of credentials on a deployed MiCADO Master
- Add demo ADTs for Azure & GCE
- Update QuickStart docs in README
- Bump Grafana to v6.6.2
- Bump Prometheus to v2.16.0
- Bump Kubernetes-Dashboard to v2.0.0 (rc7)
- Hide Kubernetes Secrets on Kubernetes-Dashboard
- Refactor PK main loop to support multiple cloud orchestrators
- Add Terraform handler to PK for scaling (up/down and dropping specific nodes)
- Switch to the *pykube* package in PK instead of *kubernetes*
- Add the TerraformAdaptor to the TOSCASubmitter
- Bump TOSCASubmitter package versions
- Discover cloud from TOSCA ADT type and deprecate *interface_cloud*
- Rename ADT compute property *endpoint_cloud* to *endpoint*
- Support *insert* in ADT to modify cloud-init cloud-config
- Support authentication with OpenStack application credential
- Pass orchestrator info to PK during PKAdaptor translation
- Lower reserved CPU and Memory for Zorp Ingress on workers
- Only deploy Zorp Ingress to workers with matching ADT policy
- Bump Kubernetes to v1.18
- Bump Flannel to v0.12
- Bump containerd.io to v.1.2.13
- Bump Occopus to v1.7 (rc6)
- Bump cAdvisor to v0.34.0
- Bump AlertManager to v0.20.0

v0.8.0 (30 September 2019)
==========================
- simplify ADTs by introducing pre-defined TOSCA node types
- add support for Kubernetes ConfigMaps, Namespaces and multi-container Pods
- metric collection (disabled by default) is now enabled with "monitoring" policy
- upgrade all components (Docker, Kubernetes, Grafana, Prometheus, etc...)
- introduce new Optimizer supported scaling
- add MiCADO version on dashboard and Grafana
- introduce log rotate for Docker and components
- introduce node downscale mechanism with node selection
- redirect stdout of scaling_rule usercode to different log file
- add support of keystone V3 for OpenStack in Occopus
- improve cloud API handling in Occopus
- make the master node web authentication timeout configurable
- make master-worker node VPN connection more restrictive
- implement ADT-based application secret distribution
- push cloud secrets to Credential Store at deploy time
- implement Security Policy Manager adaptor in the TOSCA Submitter
- add support for configuring application-level firewalling rules for the application through the ADT (FWaaS)
- generate node certificate with the right common name for the master node
- make the micadoctl command line utility to work after the transition to Kubernetes pods
- fix keypair distribution to worker nodes
- update TOSCA template for Kubernetes application-level secret distribution
- refactor Kubernetes translation
- fix Policy Keeper Kubernetes node maintenance
- propagate Kubelet configuration to woker nodes
- support system cGroup driver by Docker & Kubernetes
- fix Kubernetes node objects to be deleted on "undeploy"
- fix Occopus create & import actions to correctly raise exceptions
- fix Occopus updates not to kill unrelated nodes
- support updates of an ADT with no Occopus nodes
- support updates of an ADT with no Kubernetes nodes
- add a timeout to Kubernetes undeploy
- simplify hosts.yml file

v0.7.3 (14 Jun 2019)
====================

- update MiCADO internal core services to run in Kubernetes pods
- remove Consul and replace it with Prometheus’ Kubernetes Service Discovery
- update cAdvisor and NodeExporter to run as Kubernetes DaemonSets
- introduce the support for creating prepared image for the MiCADO master and the MiCADO worker
- introduce the support for deploying unique “sets” of virtual machines scaling independently
- update Grafana to track the independently scaling VMs from the drop-down Node ID
- update scrape interval between Prometheus and cAdvisor to be less frequent
- fix the Occopus Adaptor to correctly raise exceptions for the submitter
- update Kubernetes Dashboard to improve RBAC permissions
- update the Flannel Overlay deployment
- update the Kubernetes eviction thresholds on the Master node to be lowered
- remove Docker-Compose from Master & Workers
- fix dependencies and vulnerabilities
- add dry-run support for the Submitter upon launch of TOSCA ADT
- add new api call for the Submitter to validate TOSCA template
- improve Submitter logs
- improve Submitter responses to users
- improve handling of wrong template by Submitter
- add support for hv_relaxed and hv_tsc CloudSigma specific properties
- add support for tagging EC2 type resources
- add disk and free space checking to the deployment playbook
- update the Wordpress demo to demonstrate “virtual machine sets”
- update the cQueue demo to demonstrate “virtual machine sets”
- fix and improve the NGINX demo

v0.7.2-rev1 (01 Apr 2019)
=========================

- fix dependency issue for Kubernetes 1.13.1 (`kubernetes/kubernetes#75683 <https://github.com/kubernetes/kubernetes/issues/75683>`__)

v0.7.2 (25 Feb 2019)
====================

- add checking for minimal memory on micado master at deployment
- support private networks on cloudsigma
- support user-defined contextualisation
- support re-use across other container & cloud orchestrators in ADT
- new TOSCA to Kubernetes Manifest Adaptor
- add support for creating DaemonSets, Jobs, StatefulSets (with limited functionality) and standalone Pods
- add support for creating PersistentVolumes & PVClaims
- add support for specifying custom service details (NodePort, ClusterIP, etc.)
- minor improvements to Grafana dashboard
- support asynchronous calls through TOSCASubmitter API
- fix kubectl error on MiCADO Master restart
- fix TOSCASubmitter rollback on errors
- fix TOSCASubmitter status & output display
- add support for encrypting master-worker communication
- automatically provision and revoke security credentials for worker nodes
- update default MTU to 1400 to ensure compatibility with OpenStack and AWS
- add Credential Store security enabler
- add Security Policy Manager security enabler
- add Image Integrity Verifier Security enabler
- add Crypto Engine security enabler
- add support for kubernetes secrets
- reimplement Credential Manager using the flask-users library

v0.7.1 (10 Jan 2019)
====================

- Fix: Add SKIP back to Dashboard (defaults changed in v1.13.1)
- Fix: URL not found for Kubernetes manifest files
- Fix: Make sure worker node sets hostname correctly
- Fix: Don't update Kubernetes if template not changed
- Fix: Make playbook more idempotent
- Add Support for outputs via TOSCA ADT
- Add Kubernetes service discovery support to Prometheus
- Add new demo: nginx (HTTP request scaling)

v0.7.0 (12 Dec 2018)
====================
- Introduce Kubernetes as the primary container orchestration engine
- Replace the swarm-visualiser with the Kubernetes Dashboard

Older MiCADO Versions
=====================

**v0.6.1 (15 Oct 2018)**

- enable VM-only deployments
- add support for special characters in SSL credentials
- fix missing vm instance number reset at undeployment
- add option to disable auto-updates on worker nodes
- modify default launch-order of TOSCA adaptors
- add cloud-specific TOSCA templates and improve helper scripts for stressng
- flatten CPU scaling policies
- improve virtual machine build time
- fix Zorp starting dependency
- fix Docker login timing issue
- remove unnecessary port from docker compose file
- enable Prometheus DB export

**v0.6.0 (10 Sept 2018)**

- introduce documentation repository and host its content at http://micado-scale.readthedocs.io
- improve MiCADO master containers restart policy
- fix MTU issue in relation to Docker
- fix Occopus restart issue
- fix health-checking for Cloudbroker-AWS platform
- update host naming convention for worker and master nodes
- make wait-update task idempotent in ansible playbook
- fix issue with worker node deployment in EC2 clouds
- fix issue with user-defined Docker networks in OpenStack clouds
- make Submitter response message structure uniform
- add 'nodes' and 'services' query methods to REST API
- improve 'stressng' and 'cqueue' test helper scripts
- add more compose properties to custom TOSCA definition
- fix floating ip issues in the Dashboard component
- add new links to Dashboard to reflect the changes introduced by reverse proxying
- fix Dashboard to generate links based on the contents of the Host header to find the frontend URL automatically
- make consul security encryption based on generated random key instead of static key
- add reverse proxy, TLS encryption and application-level firewalling capabilities to the web interfaces exposed by the MiCADO master node
- add packet filtering for closing down non-public ports
- add systemd unit for MiCADO services
- update the ansible playbook to use the built-in service module for installing and handling MiCADO services
- update the documentation to reflect the changes after the introduction of reverse proxying
- add support for form-based authentication of exposed web services
- add COLA-themed login page
- add the Credential Manager component to store and handle web service users and passwords securely
- add support for provisioning a user to the Credential Manager via Ansible
- add support for user and admin roles in the Credential Manager
- add support for authorization of the web services based on user role
- add documentation about the Ansible Vault mechanism to protect sensitive deployment details
- add support for HTTP basic authentication for APIs
- add support for making the web interface's listening port configurable
- update the documentation of API calls in terms of authentication, encryption and reverse proxying
- add micadoctl tool for user and service management
- add HTTP method filter to firewall in order to control requests directed to containers
- add support for IPv6 exposure of services
- add IPv6 packet filtering

**v0.5.0 (12 July 2018)**

- introduce supporting TOSCA
- introduce supporting user-defined scaling policy
- dashboard added with Docker Visualizer, Grafana, Prometheus
- deployment with Ansible playbook
- support private docker registry
- improve persistence of MiCADO master services
