Planner-get-meeting-notes
========

The script will call a stored procedure and export a meeting notes as an Excel file.
The Excel file is sent as an attachment via email to the specified user.
See parameters.py for the user-input variables. 

The directory should be located on a server, where run.py can be scheduled to run automatically and regularly as a 'Windows Job':


Features
--------

- Create an Excel as a buffer file, without using any physical space
- Send email automatically if a new meeting was completed

Installation
------------

Python 3.8 must be installed on the running server.
Requirements must be installed in the environment.

```pip install requirements.txt```

or

```conda install --file requirements.txt```


Support
-------

If you are having issues, please let us know at:
alina.motygullina@mater.org.au

Copyright
-------

# Copyright 2020 Mater Misericordiae Ltd.