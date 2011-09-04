Karait
======

A ridiculously simple queuing system, with clients in various languages, built on top of MongoDB.

Examples
========

Some examples of Karait in action.

Benchmark
=========

Handy scripts for benchmarking the actual performance of the queue.

Usage
-----

* Run all three scripts in separate terminals.
* View terminal output for timings.

Shutdown
========

Demonstrates broadcast and routed messaging in the queue.

* Run ruby_process.rb and python_process.py in separate terminals.
* Run the shutdown scripts to terminate the processes.

Visibility Timeout
==================

Demonstrates the use of the visibility_timeout flag.

* Run a single writer.py.
* Run multiple reader.rb scripts.
* Due to the usage of visibility timeouts, only one reader should see each message.

Copyright
---------

Copyright (c) 2011 Attachments.me. See LICENSE.txt for
further details.