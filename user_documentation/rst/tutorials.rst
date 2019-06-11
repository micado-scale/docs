.. _tutorials:

Tutorials
*********

You can find some demo applications under the subdirectories of the ‘testing’ directory in the downloaded (and unzipped) installation package of MiCADO.

stressng
========

This application contains a single service, performing a constant CPU load. The policy defined for this application scales up/down both nodes and the stressng service based on cpu consumption. Helper scripts have been added to the directory to ease application handling.

**Note:** make sure you have the ``jq`` tool installed required by the helper scripts.

*  Step1: make a copy of the TOSCA file which is appropriate for your cloud - ``stressng_<your_cloud>.yaml`` - and name it ``stressng.yaml`` (ie. by issuing the command ``cp stressng_cloudsigma.yaml stressng.yaml``)
*  Step2: fill in the requested fields beginning with ``ADD_YOUR_...`` . These will differ depending on which cloud you are using.

   **Important:** Make sure you create the appropriate firewall policy for the MiCADO workers as described :ref:`here <workerfirewallconfig>`!

 * In CloudSigma, for example, the ``libdrive_id`` , ``public_key_id`` and ``firewall_policy`` fields must be completed. Without these, CloudSigma does not have enough information to launch your worker nodes. All information is found on the CloudSigma Web UI. ``libdrive_id`` is the long alphanumeric string in the URL when a drive is selected under “Storage/Library”. ``public_key_id`` is under the “Access & Security/Keys Management” menu as **Uuid**. ``firewall_policy`` can be found when selecting a rule defined under the “Networking/Policies” menu. The following ports must be opened for MiCADO workers: *all inbound connections from MiCADO master*

*  Step3: Update the parameter file, called ``_settings``. You need the ip address for the MiCADO master and should name the application by setting the APP_ID ***the application ID can not contain any underscores ( _ )** You should also change the SSL user/password/port information if they are different from the default.
*  Step4: run ``1-submit-tosca-stressng.sh`` to create the minimum number of MiCADO worker nodes and to deploy the Kubernetes Deployment including the stressng app defined in the ``stressng.yaml`` TOSCA description.
*  Step4a: run ``2-list-apps.sh`` to see currently running applications and their IDs
*  Step5: run ``3-stress-cpu-stressng.sh 85`` to stress the service and increase the CPU load. After a few minutes, you will see the system respond by scaling up virtual machines and containers to the maximum specified.
*  Step6: run ``3-stress-cpu-stressng.sh 10`` to update the service and decrease the CPU load. After a few moments the system should respond by scaling down virtual machines and containers to the minimum specified.
*  Step7: run ``4-undeploy-stressng.sh`` to remove the stressng stack and all the MiCADO worker nodes

cqueue
======

This application demonstrates a deadline policy with CQueue. CQueue provides a lightweight queueing service for executing containers. The entire infrastructure will be deployed by a single ADT as a microservices architecture. CQueue server (implemented by RabbitMQ, Redis and a web-based frontend) will be run on a static VM in the cluster. The server stores items in a queue where each item represents a container execution. CQueue workers will run on a separate set of scalable VMs, and are responsible for fetching items and preforming the execution of the container locally. The demonstration below shows that the items can be consumed before a deadline using MiCADO for scaling the CQueue worker and its VM nodes.

If you prefer to launch your own cQueue server externally, use the docker-compose file ``docker-compose-cqueue-server.yaml`` and edit the relevant shell scripts to point to your server and to launch ``micado-cqworker.yaml`` instead.

**Note:** make sure you have the ``jq`` tool installed required by the helper scripts.

*  Step1: Update the file cq-microservice.yaml with the CloudSigma ID details necessary to launch your **two** VM sets

    -  Update each ‘ADD_YOUR_ID_HERE’ string with the proper value retrieved under your CloudSigma account.
    -  Make sure port 30888 is open on the ``cq-server`` virtual machine set

*  Step2: Update the parameter file, called ``_settings`` . You need the ip address for the MiCADO master and, once your worker nodes are running, you should enter the IP for the CQueue server which is about to be deployed. Setting the IP of the CQueue server is a required step if your MiCADO Master does not have the appropriate port open.
*  Step3: Run ``./1-deploy-cq-microservices.sh`` to deploy the cQueue server and worker components to separate virtual machine nodes
*  Step4: Use your Cloud WebUI and find the public IP of the VM hosting the cQueue server (in fact, this can be **any** VM in your cluster with port 30888 open)
*  Step5: Run ``./3-get_date_in_epoch_plus_seconds.sh 600`` to calculate the unix timestamp representing the deadline by which the items (containers) must be finished. Take the value from the last line of the output produced by the script. The value is 600 seconds from now.
*  Step6: Run ``./4-update-cqueue-deadline.sh xxxxxxx`` where **xxxxxxx** is the unix timestamp taken from the previous step.
*  Step7: Run ``./5-submit-jobs.sh 50`` to generate and send 50 jobs to CQueue server. Each item will be a simple Hello World app (combined with some sleep) realized in a container. You can later override this with your own container.
*  Step8a: You can run ``./2-list-running-apps.sh`` to list the apps running under MiCADO.
*  Step8b: You can run ``query-services.sh`` to see the details of docker services of your application
*  Step8c: You can run ``query-nodes.sh`` to see the details of docker nodes hosting your application
*  Step9: Run ``./6-undeploy-cq-microservices.sh`` to remove your application from MiCADO when all items are consumed.
*  Step10: You can have a look at the state ``./cqueue-get-job-status.sh <task_id>`` or stdout of container executions ``./cqueue-get-job-status.sh <task_id>`` using one of the task id values printed during Step 3.

nginx
========

This application deploys a http server with nginx. The container features a built-in prometheus exporter for HTTP request metrics. The policy defined for this application scales up/down both nodes and the nginx service based on active http connections. wrk (apt-get install wrk | https://github.com/wg/wrk) is recommended for HTTP load testing.

**Note:** make sure you have the ``jq`` tool and ``wrk`` benchmarking app installed as these are required by the helper scripts. Best results for ``wrk`` are seen on multi-core systems.

*  Step1: make a copy of the TOSCA file which is appropriate for your cloud - ``nginx_<your_cloud>.yaml`` - and name it ``nginx.yaml``
*  Step2: fill in the requested fields beginning with ``ADD_YOUR_...`` . These will differ depending on which cloud you are using.

   **Important:** Make sure you create the appropriate firewall policy for the MiCADO workers as described :ref:`here <workerfirewallconfig>`!

 * In CloudSigma, for example, the ``libdrive_id`` , ``public_key_id`` and ``firewall_policy`` (port 30012 must be open) fields must be completed. Without these, CloudSigma does not have enough information to launch your worker nodes. All information is found on the CloudSigma Web UI. ``libdrive_id`` is the long alphanumeric string in the URL when a drive is selected under “Storage/Library”. ``public_key_id`` is under the “Access & Security/Keys Management” menu as **Uuid**. ``firewall_policy`` can be found when selecting a rule defined under the “Networking/Policies” menu. The following ports must be opened for MiCADO workers: *all inbound connections from MiCADO master*

*  Step3: Update the parameter file, called ``_settings``. You need the ip address for the MiCADO master and should name the deployment by setting the APP_ID. ***the application ID can not contain any underscores ( _ )** The APP_NAME must match the name given to the application in TOSCA (default: **nginxapp**) You should also change the SSL user/password/port information if they are different from the default.
*  Step4: run ``1-submit-tosca-nginx.sh`` to create the minimum number of MiCADO worker nodes and to deploy the Kubernetes Deployment including the nginx app defined in the ``nginx.yaml`` TOSCA description.
*  Step4a: run ``2-list-apps.sh`` to see currently running applications and their IDs, as well as the ports forwarded to 8080 for accessing the HTTP service, which should now be accessible on <micado_worker_ip>:30012
*  Step5: run ``3-generate-traffic.sh`` to generate some HTTP traffic. After thirty seconds or so, you will see the system respond by scaling up containers, and eventually virtual machines to the maximum specified. **NOTE:** In some cases, depending on your cloud, the pre-configured load test may be too weak to trigger a scaling response from MiCADO. If this is the case, edit the file ``3-generate-traffic.sh`` and increase the load options in the command on the very last line, for example ``wrk -t4 -c40 -d8m http://.....`` On the other hand, a load test too powerful will be like launching a denial-of-service attack on yourself.
*  Step5a: the load test will finish after 10 minutes and the infrastructure will scale back down
*  Step6: run ``4-undeploy-nginx.sh`` to remove the nginx deployment and all the MiCADO worker nodes

wordpress
=========

This application deploys a wordpress blog, complete with MySQL server and a Network File Share for peristent data storage. It is a proof-of-concept and is **NOT** production ready. The policy defined for this application scales up/down both nodes and the wordpress frontend container based on network load. wrk (apt-get install wrk | https://github.com/wg/wrk) is recommended for HTTP load testing, but you can use any load generator you wish.

**Note:** make sure you have the ``jq`` tool and ``wrk`` benchmarking app installed as these are required by the helper scripts to force scaling. Best results for ``wrk`` are seen on multi-core systems.

*  Step1: make a copy of the TOSCA file which is appropriate for your cloud - ``wordpress_<your_cloud>.yaml`` - and name it ``wordpress.yaml``
*  Step2: fill in the requested fields beginning with ``ADD_YOUR_...`` . These will differ depending on which cloud you are using.

   **Important:** Make sure you create the appropriate firewall policy (port 30010 must be open) for the MiCADO workers as described :ref:`here <workerfirewallconfig>`!

 * In CloudSigma, for example, the ``libdrive_id`` , ``public_key_id`` and ``firewall_policy`` fields must be completed. Without these, CloudSigma does not have enough information to launch your worker nodes. All information is found on the CloudSigma Web UI. ``libdrive_id`` is the long alphanumeric string in the URL when a drive is selected under “Storage/Library”. ``public_key_id`` is under the “Access & Security/Keys Management” menu as **Uuid**. ``firewall_policy`` can be found when selecting a rule defined under the “Networking/Policies” menu. The following ports must be opened for MiCADO workers: *all inbound connections from MiCADO master*

*  Step3: Update the parameter file, called ``_settings``. You need the ip address for the MiCADO master and should name the deployment by setting the APP_ID. ***the application ID can not contain any underscores ( _ )** The FRONTEND_NAME: must match the name given to the application in TOSCA (default: **wordpress**) You should also change the SSL user/password/port information if they are different from the default.
*  Step4: run ``1-submit-tosca-wordpress.sh`` to create the minimum number of MiCADO worker nodes and to deploy the Kubernetes Deployments for the NFS and MySQL servers and the Wordpress frontend.
*  Step4a: run ``2-list-apps.sh`` to see currently running applications and their IDs, as well as the nodePort open on the host for accessing the HTTP service (defaults to 30010)
*  Step5: navigate to your wordpress blog (generally at <worker_node_ip>:30010) and go through the setup tasks until you can see the front page of your blog
*  Step6: run ``3-generate-traffic.sh`` to generate some HTTP traffic. After thirty seconds or so, you will see the system respond by scaling up a VM and containers to the maximum specified. **NOTE:** In some cases, depending on your cloud, the pre-configured load test may be too weak to trigger a scaling response from MiCADO. If this is the case, edit the file ``3-generate-traffic.sh`` and increase the load options in the command on the very last line, for example ``wrk -t4 -c40 -d8m http://.....`` On the other hand, a load test too powerful will be like launching a denial-of-service attack on yourself.
*  Step6a: the load test will stop after 10minutes and the infrastructure will scale back down
*  Step7: run ``4-undeploy-wordpress.sh`` to remove the wordpress deployment and all the MiCADO worker nodes
