# Changelog

## 0.3.3-alpha

## 0.3.2 - 2016-02-24

* hashring fixes
* add meta.name for usage messages so subcommands can be reused by other
  projects
* clean up repr and move to \_.
* add Host header to http client requests, fix http client User-Agent
* fix bug in chunk transfer encoding parsing
* fix bug in lua msgpack bindings where array/map end states weren't expected
  from the parser
* pull in siphon empty map / array msgpack fix
* improve error logging when coroutines error
* fix composing Host header in http client
* for binaries built by levee, add a package.loader that attempts to open
  linked bundles via dsym
* fix for http's :save convenience on Linux
* small fixes for \_.open and io:open
* bring Consul support back up to date
* fix for linux 0copy splice
* fix 100% cpu waitpid bug in levee.core.process
* add the beginnings of a jinja2-esque template library
* add ability to bundle static assets into a levee binary
* add the beginnings of a micro-web framework http:droplet
* add ability to bundle templates into a levee binary
* fix a bug where file descriptors weren't being cleaned up on a failed TCP
  connect
* add h.consul:spawn, to facilitate spawning consul instances for testing
* add a broadcast message primitive

## 0.3.1 - 2015-12-03

* first tagged release
