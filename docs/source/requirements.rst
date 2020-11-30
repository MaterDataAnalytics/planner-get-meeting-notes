Requirements
=============

Current version is built in Python 3.8.
It is recommended to use a virtual environment to run the script.
When a new virtual environment started, requirements must be installed:

.. code-block:: bash

    pip install requirements.txt

or if Anaconda is used:

.. code-block:: bash

    conda install --file requirements.txt

The requirements can be updated manually by running:

.. code-block:: bash

    pipreqs --clean requirements.txt

or to overwrite completely:

.. code-block:: bash

    pipreqs requirements.txt
