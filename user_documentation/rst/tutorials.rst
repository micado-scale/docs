Tutorials
*********

You can find test application(s) under the subdirectories of the ‘testing’ directory. The current tests are configured for CloudSigma.

stressng
========

This application contains a single service, performing constant load. Policy defined for this application scales up/down both nodes and the stressng service based on cpu consumption. Helper scripts has been added to the directory to ease application handling.

*  Step1: add your ``public_key_id`` to both the ``stressng.yaml`` and ``stressng-update.yaml`` files. Without this CloudSigma does not execute the contextualisation on the MiCADO worker nodes. The ID must point to your public ssh key under your account in CloudSigma. You can find it on the CloudSigma Web UI under the “Access & Security/Keys Management” menu.
* Step2: add a proper ``firewall_policy`` to both the ``stressng.yaml`` and ``stressng-update.yaml`` files. Without this MiCADO master will not reach MiCADO worker nodes. Firewall policy ID can be retrieved from a rule defined under the “Networking/Policies” menu. The following ports must be opened for MiCADO workers: all inbound connections from MiCADO master
*  Step3: set the MICADO_MASTER variable to contain the IP of the MiCADO master node with ``export MICADO_MASTER=a.b.c.d``
*  Step4: run ``1-submit-tosca-stressng.sh`` to create the minimum number of MiCADO worker nodes and to deploy the docker stack including the stressng service defined in the ``stressng.yaml`` TOSCA description. Optionally, add as an argument a user-defined application id (ie. ``1-submit-tosca-stressng.sh stressng`` ). The system should respond by scaling up virtual machines and containers to the maximum specified.
*  Step4a: run ``2-list-apps.sh`` to see currently running applications and their IDs
*  Step5: run ``3-update-tosca-stressng.sh <ID>`` with the appropriate ID to update the service and reduce the CPU load. The system should respond by scaling down virtual machines and containers to the minimum specified.
*  Step6: run ``4-undeploy-with-id.sh <ID>`` with the appropriate ID to remove the stressng stack and all the MiCADO worker nodes

cqueue
======

This application demonstrates a deadline policy using CQueue. CQueue provides a lightweight queueing service for executing containers. CQueue server (implemented by RabbitMQ, Redis and a web-based frontend) stores items where each represents a container execution. CQueue worker fetches an item and preform the execution of the container locally. The demonstration below shows that the items can be consumed by deadline using MiCADO for scaling the CQueue worker. The demonstration requires the deployment of a CQueue server separately, then the submission of the CQueue worker to MiCADO with the appropriate (predefined) scaling policy.

*  Step1: Launch a separate VM and deploy CQueue server using the compose file, called ``docker-compose-cqueue-server.yaml``. You need to install docker and docker-compose to use the compose file. This will be your cqueue server to store items representing container execution requests. Important: you have to open ports defined under the ‘ports’ section for each of the four services defined in the compose file.
*  Step2: Update the parameter file, called ``_settings`` . You need the ip address for the MiCADO master and for the CQueue server.
*  Step3: Run ``./1-submit-jobs.sh 50`` to generate and send 50 jobs to CQueue server. Each item will be a simple Hello World app (combined with some sleep) realized in a container. You can later override this with your own container.
*  Step4: Edit the TOSCA description file, called ``micado-cqworker.yaml``.

    -  Replace each ‘cqueue.server.ip.address’ string with the real ip of CQueue server.
    -  Update each ‘ADD_YOUR_ID_HERE’ string with the proper value retrieved under your CloudSigma account.

*  Step5: Run ``./2-get_date_in_epoch_plus_seconds.sh 600`` to calculate the unix timestamp representing the deadline by which the items (containers) must be finished. Take the value from the last line of the output produced by the script. The value is 600 seconds from now.
*  Step6: Edit the TOSCA description file, called ``micado-cqworker.yaml``.

    -  Update the value for the ‘DEADLINE’ which is under the ‘policies/scalability/properties/constants’ section. The value has been extracted in the previous step. Please, note that defining a deadline in the past results in scaling the application to the maximum (2 nodes and 10 containers).

*  Step7: Run ``./3-deploy-cq-worker-to-micado.sh`` to deploy the CQworker service, which will consume the items from the CQueue server i.e. execute the containers specified by the items.
*  Step8: Monitor the application:

    -  visit https://[micado.master.ip]:[port]/docker-visualizer to see the number of nodes and containers.
    -  watch the log of policy keeper on the MiCADO master    (/var/log/micado/policykeeper).

*  Step9: Run ``./4-list-running-apps.sh`` to list the apps you are running under MiCADO.
*  Step10: Run ``./5-undeploy-cq-worker-from-micado.sh`` to remove your application from MiCADO when all items are consumed.
*  Step11: You can have a look at the state ``./cqueue-get-job-status.sh <task_id>`` or stdout of container executions ``./cqueue-get-job-status.sh <task_id>`` using one of the task id values printed during Step 3.
