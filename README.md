Buildiot
========

Automatic DEB package generator from Git branches. Currently in weak alpha.

System requirements
-------------------

**Linux** or other UNIX system (not tested, use at your own risc)

**Ruby 1.8** or newer with installed **Rubygems**

Usage
-----

    ./buildiot.rb <rules_file>
      
Rules
-----

JSON file. You can see *example.buildiot* as a simple example.

The first level of JSON tree **must** contain the following parameters:
* `name` — package basic name (string);
* `vcs` — version control system you use; currently only **git** supported (string);
* `source` — local or remote address of Git repo used for package generation (string);
* `maintainer` — package maintainer data (string);
* `versions` — parent tree for information which package version you need to build from different Git branches (details below);
* `destination` — contains information about which files must be moved to some directories during package installation (array of hashes).

Optional parameters of the first tree level:
* `arch` — package architecture (string);
* `outdir` — the directory generated packages will be saved to (string);
* `description` — package description (array of strings);
* `deps`, `predeps`, `builddeps` — basic, pre- and build dependences for package (arrays of strings);
* `dirs` — list of empty directories must be created during package installation (array of strings);
* `conffiles` — list of configuration files of your software (dpkg asks about re-writing them during package updates) (array of strings);
* `preinst`, `postinst`, `prerm`, `postrm` — path to appropriate executable files for DEB package; in case its path starts from **/** character, they are looked in local filesystem, otherwise they are looked inside Git repo (strings);
* `prebuild` — path to script should be executed before package generation starts e.g. compilation of sources received from Git repo (string).

## 'versions' tree
The first level of *versions* tree should contain numbers of the versions you need to build (examples: `1.0`, `3.3-dev`, `1.3.2+squeeze1`). Every version number is root for the following tree items:
* `branch` — name of the branch you need to build an actual version from (string);
* any optional parameters (and **destination** from required) may be overrided there.

For some details about DEB packages please refer [official policy](http://www.debian.org/doc/debian-policy/).

License
-------

All this project's source codes licensed under [WTFPL](http://sam.zoy.org/wtfpl/), but I would be grateful for your contribution whatever that may mean :).
