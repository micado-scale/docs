REST API
********

MiCADO has a TOSCA compliant submitter to submit, update, list and remove MiCADO applications. The submitter exposes the following REST API:

*  To launch an application specified by a TOSCA description stored locally, use this command:

::

   curl -F file=@[path to the TOSCA description] -X POST http://[IP]/toscasubmitter/v1.0/app/launch/file/

*  To launch an application specified by a TOSCA description stored locally and specify an application id, use this command:

::

   curl -F file=@[path to the TOSCA description] -F id=[APPLICATION_ID]  -X POST http://[IP]/toscasubmitter/v1.0/app/launch/file/

*  To launch an application specified by a TOSCA description stored behind a url, use this command:

::

   curl -d input="[url to TOSCA description]" -X POST http://[IP]/toscasubmitter/v1.0/app/launch/url/

*  To launch an application specified by a TOSCA description stored behind an url and specify an application id, use this command:

::

   curl -d input="[url to TOSCA description]" -d id=[ID] -X POST http://[IP]/toscasubmitter/v1.0/app/launch/url/

*  To update a running MiCADO application using a TOSCA description stored locally, use this command:

::

   curl -F file=@"[path to the TOSCA description]" -X PUT http://[IP]/toscasubmitter/v1.0/app/udpate/file/[APPLICATION_ID]

*  To update a running MiCADO application using a TOSCA description stored behind a url, use this command:

::

   curl -d input="[url to TOSCA description]" -X PUT http://[IP]/toscasubmitter/v1.0/app/udpate/file/[APPLICATION_ID]

*  To undeploy a running MiCADO application, use this command:

::

   curl -X DELETE http://[IP]/toscasubmitter/v1.0/app/undeploy/[APPLICATION_ID]

*  To query all the running MiCADO applications, use this command:

::

   curl -X GET http://[IP]/toscasubmitter/v1.0/list_app/

*  To query one running MiCADO application, use this command:

::

   curl -X GET http://[IP]/toscasubmitter/v1.0/app/[APPLICATION_ID]