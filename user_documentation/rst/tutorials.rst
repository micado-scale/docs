.. _tutorials:

Tutorials
*********

You can find test application(s) under the subdirectories of the ‘testing’ directory. The current **stressng** test can be configured for use with CloudSigma, AWS EC2, OpenStack Nova and deployments via CloudBroker. The current **cqueue** test is configured for CloudSigma.

stressng
========

This application contains a single service, performing a constant CPU load. The policy defined for this application scales up/down both nodes and the stressng service based on cpu consumption. Helper scripts have been added to the directory to ease application handling.

**Note:** make sure you have the ``jq`` tool installed required by the helper scripts.

*  Step1: make a copy of the TOSCA file which is appropriate for your cloud - ``stressng_<your_cloud>.yaml`` - and name it ``stressng.yaml`` (ie. by issuing the command ``cp stressng_cloudsigma.yaml stressng.yaml``)
*  Step2: fill in the requested fields beginning with ``ADD_YOUR_...`` . These will differ depending on which cloud you are using.
 * In CloudSigma, for example, the ``libdrive_id`` , ``public_key_id`` and ``firewall_policy`` fields must be completed. Without these, CloudSigma does not have enough information to launch your worker nodes. All information is found on the CloudSigma Web UI. ``libdrive_id`` is the long alphanumeric string in the URL when a drive is selected under “Storage/Library”. ``public_key_id`` is under the “Access & Security/Keys Management” menu as **Uuid**. ``firewall_policy`` can be found when selecting a rule defined under the “Networking/Policies” menu. The following ports must be opened for MiCADO workers: *all inbound connections from MiCADO master*
*  Step3: Update the parameter file, called ``_settings``. You need the ip address for the MiCADO master and should name the application by setting the APP_ID  ***the application ID can not contain any underscores ( _ )** You should also change the SSL user/password/port information if they are different from the default.
*  Step4: run ``1-submit-tosca-stressng.sh`` to create the minimum number of MiCADO worker nodes and to deploy the Kubernetes Deployment including the stressng app defined in the ``stressng.yaml`` TOSCA description.
*  Step4a: run ``2-list-apps.sh`` to see currently running applications and their IDs
*  Step5: run ``3-stress-cpu-stressng.sh 85`` to stress the service and increase the CPU load. After a few minutes, you will see the system respond by scaling up virtual machines and containers to the maximum specified.
*  Step6: run ``3-stress-cpu-stressng.sh 10`` to update the service and decrease the CPU load. After a few moments the system should respond by scaling down virtual machines and containers to the minimum specified.
*  Step7: run ``4-undeploy-stressng.sh`` to remove the stressng stack and all the MiCADO worker nodes

cqueue
======

This application demonstrates a deadline policy using CQueue. CQueue provides a lightweight queueing service for executing containers. CQueue server (implemented by RabbitMQ, Redis and a web-based frontend) stores items where each represents a container execution. CQueue worker fetches an item and preform the execution of the container locally. The demonstration below shows that the items can be consumed by deadline using MiCADO for scaling the CQueue worker. The demonstration requires the deployment of a CQueue server separately, then the submission of the CQueue worker to MiCADO with the appropriate (predefined) scaling policy.

**Note:** make sure you have the ``jq`` tool installed required by the helper scripts.

*  Step1: Launch a separate VM and deploy CQueue server using the compose file, called ``docker-compose-cqueue-server.yaml``. You need to install docker and docker-compose to use the compose file. This will be your cqueue server to store items representing container execution requests. Important: you have to open ports defined under the ‘ports’ section for each of the four services defined in the compose file.
*  Step2: Update the parameter file, called ``_settings`` . You need the ip address for the MiCADO master and for the CQueue server.
*  Step3: Run ``./1-submit-jobs.sh 50`` to generate and send 50 jobs to CQueue server. Each item will be a simple Hello World app (combined with some sleep) realized in a container. You can later override this with your own container.
*  Step4: Edit the TOSCA description file, called ``micado-cqworker.yaml``.

    -  Replace each ‘cqueue.server.ip.address’ string with the real ip of CQueue server.
    -  Update each ‘ADD_YOUR_ID_HERE’ string with the proper value retrieved under your CloudSigma account.

*  Step5: Run ``./2-get_date_in_epoch_plus_seconds.sh 600`` to calculate the unix timestamp representing the deadline by which the items (containers) must be finished. Take the value from the last line of the output produced by the script. The value is 600 seconds from now.
*  Step6: Edit the TOSCA description file, called ``micado-cqworker.yaml``.

    -  Update the value for the ‘DEADLINE’ which is under the ‘policies/scalability/properties/constants’ section. The value has been extracted in the previous step. Please, note that defining a deadline in the past results in scaling the application to the maximum (2 nodes and 10 containers).

*  Step7: Run ``./3-deploy-cq-worker-to-micado.sh`` to deploy the CQworker service, which will consume the items from the CQueue server i.e. execute the containers specified by the items.
*  Step8a: Run ``./4-list-running-apps.sh`` to list the apps running under MiCADO.
*  Step8b: run ``query-services.sh`` to see the details of docker services of your application
*  Step8c: run ``query-nodes.sh`` to see the details of docker nodes hosting your application
*  Step9: Run ``./5-undeploy-cq-worker-from-micado.sh`` to remove your application from MiCADO when all items are consumed.
*  Step10: You can have a look at the state ``./cqueue-get-job-status.sh <task_id>`` or stdout of container executions ``./cqueue-get-job-status.sh <task_id>`` using one of the task id values printed during Step 3.

nginx
========

This application deploys a http server with nginx. The container features a built-in prometheus exporter for HTTP request metrics. The policy defined for this application scales up/down both nodes and the nginx service based on active http connections. wrk (apt-get install wrk | https://github.com/wg/wrk) is recommended for HTTP load testing.

**Note:** make sure you have the ``jq`` tool and ``wrk`` benchmarking app installed as these are required by the helper scripts. Best results for ``wrk`` are seen on multi-core systems.

*  Step1: make a copy of the TOSCA file which is appropriate for your cloud - ``nginx_<your_cloud>.yaml`` - and name it ``nginx.yaml``
*  Step2: fill in the requested fields beginning with ``ADD_YOUR_...`` . These will differ depending on which cloud you are using.
 * In CloudSigma, for example, the ``libdrive_id`` , ``public_key_id`` and ``firewall_policy`` fields must be completed. Without these, CloudSigma does not have enough information to launch your worker nodes. All information is found on the CloudSigma Web UI. ``libdrive_id`` is the long alphanumeric string in the URL when a drive is selected under “Storage/Library”. ``public_key_id`` is under the “Access & Security/Keys Management” menu as **Uuid**. ``firewall_policy`` can be found when selecting a rule defined under the “Networking/Policies” menu. The following ports must be opened for MiCADO workers: *all inbound connections from MiCADO master*
*  Step3: Update the parameter file, called ``_settings``. You need the ip address for the MiCADO master and should name the deployment by setting the APP_ID. ***the application ID can not contain any underscores ( _ )** The APP_NAME must match the name given to the application in TOSCA (default: **nginxapp**)  You should also change the SSL user/password/port information if they are different from the default.
*  Step4: run ``1-submit-tosca-nginx.sh`` to create the minimum number of MiCADO worker nodes and to deploy the Kubernetes Deployment including the nginx app defined in the ``nginx.yaml`` TOSCA description.
*  Step4a: run ``2-list-apps.sh`` to see currently running applications and their IDs, as well as the ports forwarded to 8080 for accessing the HTTP service
*  Step5: run ``3-generate-traffic.sh`` to generate some HTTP traffic. After thirty seconds or so, you will see the system respond by scaling up containers, and eventually virtual machines to the maximum specified.
*  Step6: run ``4-undeploy-nginx.sh`` to remove the nginx deployment and all the MiCADO worker nodes