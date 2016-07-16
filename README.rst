|License| |Build Status| |SIMP compatibility|

SIMP Logstash Puppet Component Module
=====================================

Table of Contents
-----------------

#. `Overview <#overview>`__
#. `Setup - The basics of getting started with simp_logstash <#setup>`__

   -  `What simp_logstash Affects <#what-simp_logstash-affects>`__
   -  `Setup Requirements <#setup-requirements>`__
   -  `Beginning with simp_logstash <#beginning-with-simp_logstash>`__

      - `Configuring a Combined Logstash and Elasticsearch System <#configuring-a-combined-logstash-and-elasticsearch-system>`__
      - `Directing Logstash to an External Elasticsearch System <#directing-logstash-to-an-external-elasticsearch-system>`__

        - `Setting up the Logstash System <#setting-up-the-logstash-system>`__
        - `Setting up the Elasticsearch System <#setting-up-the-elasticsearch-system>`__

#. `Limitations <#limitations>`__
#. `Development - Guide for contributing to the module <#development>`__

   -  `Acceptance Tests - Beaker env variables <#acceptance-tests>`__

Overview
--------

A module to integrate the `upstream logstash module <https://github.com/elastic/puppet-logstash>`__ into the SIMP ecosystem.

This is a SIMP component module
-------------------------------

This module is a component of the `System Integrity Management
Platform <https://github.com/NationalSecurityAgency/SIMP>`__, a
compliance oriented framework built on Puppet.

If you find any issues, they can be submitted to our
`JIRA <https://simp-project.atlassian.net/>`__.

Please read our `Contribution
Guide <https://simp-project.atlassian.net/wiki/display/SD/Contributing+to+SIMP>`__
and visit our `developer
wiki <https://simp-project.atlassian.net/wiki/display/SD/SIMP+Development+Home>`__.

As a component module, this module is not recommended for use outside of a SIMP
environment but may work with some minor modification.

Setup
-----

What simp_logstash affects
^^^^^^^^^^^^^^^^^^^^^^^^^^

This module will install Java on your system and will configure a Logstash
server to collect logs from syslog and TLS protected syslog as well as pushing
the output to either a local file or to an Elasticsearch cluster.

Any logstash input or output is supported, but only plain file and
Elasticsearch outputs are built in at this point.

The module has been tested against a remote Rsyslog client using both TLS and
non-TLS connections. Since Stunnel is used to encrypt remote connections, if
the backing Logstash server dies, Rsyslog will **not** failover between
Logstash connections unless Stunnel dies as well. This is something that we
will look toward remediating in the future.

Setup Requirements
^^^^^^^^^^^^^^^^^^

The only thing necessary to begin using simp_logstash is to install it
into your module path.

Beginning with simp_logstash
----------------------------

The remaining documentation assumes that you wish to feed your data directly
into Elasticsearch.

Configuring a Combined Logstash and Elasticsearch System
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

In general, you're going to want to have a local Elasticsearch ingest node on
each Logstash server. While not required, this is preferred so that network
connectivity issues do not cause Logstash to hang on output delivery and input
processing.

To set this up, you would simply `include '::simp_elasticsearch'` and
`include '::simp_logstash'` and apply the following Hiera code.

Please note that communications between Elasticsearch nodes will not be
encrypted by default. To gain ES communication protection, you can look at
commercial solutions from Elastic, or you can apply the `SIMP IPSec Module`_.

.. code:: yaml

  ---
  # The networks that you want to allow to connect to your systems
 
  client_nets:
   - '1.2.3.4/16'
 
  # For the IPTables redirects to the unprivileged Logstash process
 
  use_iptables : true
 
  # Elasticsearch Settings
  #
  # Internal Node setup
  #
  # Ideally, this would be randomized
 
  simp_elasticsearch::cluster_name : 'logstash'
  simp_elasticsearch::bind_host : "%{::ipaddress}"
 
  # This needs to be a list of *all* of your ES cluster hosts so that the
  # cluster works in a safe, sane manner.
  #
  # The first entry should be your local Logstash hosts. All Logstash hosts can
  # be entered if you wish to make them part of the data cluster.
 
  simp_elasticsearch::unicast_hosts :
    - "logstash1.%{::domain}:9300"
    - "es1.%{::domain}:9300"
    - "es2.%{::domain}:9300"
 
  # Logstash Settings
 
  # This is currently required due to a bug in the Elastic provided 'logstash'
  # module
 
  logstash::logstash_user : 'logstash'
  logstash::logstash_group : 'logstash'
 
  # If you want Unencrypted UDP and TCP logs (requires SIMP IPTables)
 
  simp_logstash::input::syslog::listen_plain_tcp : true
  simp_logstash::input::syslog::listen_plain_udp : true
 
  # Send all output to the local ES instance
 
  simp_logstash::outputs :
    - 'elasticsearch'

Directing Logstash to an External Elasticsearch System
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Setting up the Logstash System
""""""""""""""""""""""""""""""

Being aware of the potential issues as mentioned above if the remote
Elasticsearch system goes down, should you wish to set up your Logstash system
to point to an external Elasticsearch Cluster, you should configure it as
follows.

.. code:: yaml

  ---
  # The networks that you want to allow to connect to your systems
 
  client_nets:
   - '1.2.3.4/16'
 
  # For the IPTables redirects to the unprivileged Logstash process
 
  use_iptables : true
 
  # Logstash Settings
 
  # This is currently required due to a bug in the Elastic provided 'logstash'
  # module
 
  logstash::logstash_user : 'logstash'
  logstash::logstash_group : 'logstash'
 
  # If you want Unencrypted UDP and TCP logs (requires SIMP IPTables)
 
  simp_logstash::input::syslog::listen_plain_tcp : true
  simp_logstash::input::syslog::listen_plain_udp : true
 
  # This uses an stunnel connection to provide an encrypted connection so you
  # can only point at one node at a time. You could place this behind a load
  # balancer if you want a redundant solution.
 
  simp_logstash::output::elasticsearch::host : "es1.%{::domain}"
 
  # Send all output to the remote ES instance
 
  simp_logstash::outputs :
    - 'elasticsearch'


Setting up the Elasticsearch System
"""""""""""""""""""""""""""""""""""

The Elasticsearch system must be configured to properly accept input from the
Logstash system.

The following is the preferred configuration for a SIMP Elasticsearch
configuration.

.. code:: yaml

  # Elasticsearch Settings
  #
  # Internal Node setup
  #
  # Ideally, this would be randomized
 
  simp_elasticsearch::cluster_name : 'logstash'
  simp_elasticsearch::bind_host : "%{::ipaddress}"
 
  # Set the Apache ACL such that your Logstash client(s) can connect
  simp_elasticsearch::http_method_acl :
    'limits' :
      'hosts' :
        "ls1.%{::domain}" : 'defaults'
        "ls2.%{::domain}" : 'defaults'
 
  # This needs to be a list of *all* of your ES cluster hosts so that the
  # cluster works in a safe, sane manner.
 
  simp_elasticsearch::unicast_hosts :
    - "es1.%{::domain}:9300"
    - "es2.%{::domain}:9300"

Limitations
-----------

This module has only been tested on Red Hat Enterprise Linux 6 and 7 and CentOS
6 and 7.

Development
-----------

Please see the `SIMP Contribution Guidelines <https://simp-project.atlassian.net/wiki/display/SD/Contributing+to+SIMP>`__.

Acceptance tests
^^^^^^^^^^^^^^^^

To run the system tests, you need
`Vagrant <https://www.vagrantup.com/>`__ installed. Then, run:

.. code:: shell

    bundle exec rake beaker:suites

Some environment variables may be useful:

.. code:: shell

    BEAKER_debug=true
    BEAKER_provision=no
    BEAKER_destroy=no
    BEAKER_use_fixtures_dir_for_modules=yes

-  ``BEAKER_debug``: show the commands being run on the STU and their
   output.
-  ``BEAKER_destroy=no``: prevent the machine destruction after the
   tests finish so you can inspect the state.
-  ``BEAKER_provision=no``: prevent the machine from being recreated.
   This can save a lot of time while you're writing the tests.
-  ``BEAKER_use_fixtures_dir_for_modules=yes``: cause all module
   dependencies to be loaded from the ``spec/fixtures/modules``
   directory, based on the contents of ``.fixtures.yml``. The contents
   of this directory are usually populated by
   ``bundle exec rake spec_prep``. This can be used to run acceptance
   tests to run on isolated networks.

.. _SIMP IPSec Module: https://github.com/simp/pupmod-simp-libreswan
.. |License| image:: http://img.shields.io/:license-apache-blue.svg
   :target: http://www.apache.org/licenses/LICENSE-2.0.html
.. |Build Status| image:: https://travis-ci.org/simp/pupmod-simp-simp_logstash.svg
   :target: https://travis-ci.org/simp/pupmod-simp-simp_logstash
.. |SIMP compatibility| image:: https://img.shields.io/badge/SIMP%20compatibility-4.2.*%2F5.1.*-orange.svg
   :target: https://img.shields.io/badge/SIMP%20compatibility-4.2.*%2F5.1.*-orange.svg
