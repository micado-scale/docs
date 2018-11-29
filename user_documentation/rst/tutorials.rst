.. _tutorials:

Tutorials
*********

You can find test application(s) under the subdirectories of the ‘testing’ directory. The current **stressng** test can be configured for use with CloudSigma, AWS EC2, OpenStack Nova and deployments via CloudBroker.

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
