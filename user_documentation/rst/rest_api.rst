.. _restapi:

REST API
********

MiCADO has a TOSCA compliant submitter which enables submiting, updating, listing and removing MiCADO applications. MiCADO offers two modes for running applications:

* **Normal mode**: This is the default mode for running a MiCADO application by executing all the adaptors. 
* **Dryrun mode**: Launching a MiCADO application in *dryrun* mode tells MiCADO to simulate the execution of the adaptors without actually executing them. The *dryrun* mode is activated by setting the parameter **dryrun=True** when launching a new application.

The submitter exposes the following REST API:
---------------------------------------------

*  To **launch** an application specified by an Application Description Template (ADT) using a **local file**. You can optionally set an *ID* or run the application in *dryrun* mode:

::

   curl --insecure -F file=@<Path_to_ADT> [-F id=<APP_ID>] [-F dryrun=True] -X POST https://<username>:<password>@<IP>:<port>/toscasubmitter/v1.0/app/launch/

*  To **launch** an application specified by an ADT using a **URL**. You can optionally set an *ID* or run the application in *dryrun* mode:

::

   curl --insecure -d input="<URL_to_ADT>" [-d id=<APP_ID>] [-d dryrun=True] -X POST https://<username>:<password>@<IP>:<port>/toscasubmitter/v1.0/app/launch/

*  To **validate** an application specified by an ADT using a **local file**:

::

   curl --insecure -F file=@<Path_to_ADT> -X POST https://<username>:<password>@<IP>:<port>/toscasubmitter/v1.0/app/validate/

*  To **validate** an application specified by an ADT using a **URL**:

::

   curl --insecure -d input="<URL_to_ADT>" -X POST https://<username>:<password>@<IP>:<port>/toscasubmitter/v1.0/app/validate/


*  To **update** a running MiCADO application using a **local file**:

::

   curl --insecure -F file=@<Path_to_ADT> -X PUT https://<username>:<password>@<IP>:<port>/toscasubmitter/v1.0/app/update/<APP_ID>

*  To **update** a running MiCADO application using a **URL**:

::

   curl --insecure -d input="<URL_to_ADT>" -X PUT https://<username>:<password>@<IP>:<port>/toscasubmitter/v1.0/app/update/[APP_ID]

*  To **undeploy** a running MiCADO application:

::

   curl --insecure -X DELETE https://<username>:<password>@<IP>:<port>/toscasubmitter/v1.0/app/undeploy/[APP_ID]

*  To **list all** the running MiCADO applications:

::

   curl --insecure -X GET https://<username>:<password>@<IP>:<port>/toscasubmitter/v1.0/list_app/

*  To **query** a running MiCADO application using the application's ID:

::

   curl --insecure -X GET https://<username>:<password>@<IP>:<port>/toscasubmitter/v1.0/app/[APP_ID]/status

*  To **query the full execution status** of MiCADO:

::

   curl --insecure -X GET https://<username>:<password>@<IP>:<port>/toscasubmitter/v1.0/info_threads

*  To **query the services** of a running MiCADO application, use this command:

::

   curl --insecure -d query='services' -X GET https://<username>:<password>@<IP>:<port>/toscasubmitter/v1.0/app/query/[APP_ID]

*  To **query the nodes** hosting a running MiCADO application:

::

   curl --insecure -d query='nodes' -X GET https://<username>:<password>@<IP>:<port>/toscasubmitter/v1.0/app/query/[APP_ID]



