.. _restapi:

REST API
********

MiCADO has a TOSCA compliant submitter to submit, update, list and remove MiCADO applications. The submitter exposes the following REST API:

*  To launch an application specified by a TOSCA description stored locally (with an option in bold to specify an ID):

::

   curl --insecure -s -F file=@[path to the TOSCA template] **-F id=[APPLICATION_ID]** -X POST https://[username]:[password]@[IP]:[port]/toscasubmitter/v1.0/app/launch/

*  To launch an application specified by a TOSCA description stored behind a url (with an option in bold to specify an ID):

::

   curl --insecure -s -d input="[url to TOSCA description]" **-d id=[APPLICATION_ID]** -X POST https://[username]:[password]@[IP]:[port]/toscasubmitter/v1.0/app/launch/

*  To update a running MiCADO application using a TOSCA description stored locally, use this command:

::

   curl --insecure -s -F file=@"[path to the TOSCA description]" -X PUT https://[username]:[password]@[IP]:[port]/toscasubmitter/v1.0/app/update/[APPLICATION_ID]

*  To update a running MiCADO application using a TOSCA description stored behind a url, use this command:

::

   curl --insecure -s -d input="[url to TOSCA description]" -X PUT https://[username]:[password]@[IP]:[port]/toscasubmitter/v1.0/app/update/[APPLICATION_ID]

*  To undeploy a running MiCADO application, use this command:

::

   curl --insecure -s -X DELETE https://[username]:[password]@[IP]:[port]/toscasubmitter/v1.0/app/undeploy/[APPLICATION_ID]

*  To query all the running MiCADO applications, use this command:

::

   curl --insecure -s -X GET https://[username]:[password]@[IP]:[port]/toscasubmitter/v1.0/list_app/

*  To query one running MiCADO application, use this command:

::

   curl --insecure -s -X GET https://[username]:[password]@[IP]:[port]/toscasubmitter/v1.0/[APPLICATION_ID]/status

*  To query the full execution status of MiCADO, use this command:

::

   curl --insecure -s -X GET https://[username]:[password]@[IP]:[port]/toscasubmitter/v1.0/info_threads

*  To query the services of a running MiCADO application, use this command:

::

   curl --insecure -s -d query='services' -X GET https://[username]:[password]@[IP]:[port]/toscasubmitter/v1.0/app/query/[APPLICATION_ID]

*  To query the nodes hosting a running MiCADO application, use this command:

::

   curl --insecure -s -d query='nodes' -X GET https://[username]:[password]@[IP]:[port]/toscasubmitter/v1.0/app/query/[APPLICATION_ID]



