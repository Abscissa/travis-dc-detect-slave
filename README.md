travis-dc-detect-slave
======================

What's this for?
----------------

I got really tired of manually updating the compiler lists in the `.travis.yml` of my projects, never knowing offhand what compiler versions were available (especially for LDC/GDC) and not being able to find the DMDFE (DMD Front End) version used by of each version of LDC/GDC. This made managing `.travis.yml` files a pain.

All this compiler information should be available in one easy go-to location, and updated automatically, requiring minimal involvement/cooperation from the DMD/LDC/GDC developers (they have enough to do already!) That's what travis-dc-detect does.

What is this?
-------------

This is part of travis-dc-detect, the other part being travis-dc-detect-master.

travis-dc-detect is a system to automatically detect and publicly list all the versions of D compilers available on [travis-ci](https://travis-ci.com), along with basic version information.

This "slave" portion is a travis-ci "unittest" (not truly a unittest, but pretends to be for the sake of travis-ci) that runs on travis. This detects and reports the D compiler travis is using to the "[master](https://github.com/Abscissa/travis-dc-detect-master)" portion. The master then stores the compiler information received into a database, and generates and serves an HTML page displaying all the compiler information collected.

How travis-dc-detect works
--------------------------

**Overview:** Travis runs travis-dc-detect-slave against the latest versions of each D compiler. The travis-dc-detect-slave tool detects the compiler's information and passes it to a customizable reporting tool, by default [reporter/postToHTTPS](https://github.com/Abscissa/travis-dc-detect-slave/blob/master/reporter/postToHTTPS). Then, postToHTTPS sends the information (plus a password) to a server, travis-dc-detect-master. This travis-dc-detect-master saves the info to database and generates an HTML page for the world to see.

**Detail:**

1. **[.travis.yml](https://github.com/Abscissa/travis-dc-detect-slave/blob/master/.travis.yml) tells [travis-ci](https://travis-ci.com) to "test" travis-dc-detect-slave with the latest versions of DMD, LDC and GDC (and occasionally some older versions as well).** Instead of telling travis to test with, for example, `dmd-2.067.1`, you can omit the version number to request "latest available version". The [.travis.yml](https://github.com/Abscissa/travis-dc-detect-slave/blob/master/.travis.yml) file for travis-dc-detect-slave also tells travis to run [install-deps.sh](https://github.com/Abscissa/travis-dc-detect-slave/blob/master/install-deps.sh) to install dependencies, [run-test.sh](https://github.com/Abscissa/travis-dc-detect-slave/blob/master/run-test.sh) to do the supposed "testing", and also includes the ([encrypted](https://docs.travis-ci.com/user/encryption-keys/)) password for the server, travis-dc-detect-master.

2. **Travis runs travis-dc-detect-slave with each of the compilers.** Well, really, travis-dc-detect-slave ignores the compiler travis had automatically set up and [runs itself](https://github.com/Abscissa/travis-dc-detect-slave/blob/master/run-test.sh) with one [specific compiler](https://github.com/Abscissa/travis-dc-detect-slave/blob/master/install-deps.sh) regardless of which compiler travis is trying to "test" with. That makes maintaining travis-dc-detect-slave itself much easier.

3. **travis-dc-detect-slave checks which compiler it's supposed to test** by reading the `DC=` environment variable provided by travis. It also reads the password for for server which travis had decrypted from [.travis.yml](https://github.com/Abscissa/travis-dc-detect-slave/blob/master/.travis.yml) and stored in the environment variable `REPORTING_SERVER_PASS=`.

4. **travis-dc-detect-slave detects the current compiler's version information** by running dmd/ldc2/gdc (whichever was specified in `DC=`) with --help/--version. GDC doesn't appear to report it's DMDFE version, so there's [a helper tool](https://github.com/Abscissa/travis-dc-detect-slave/blob/master/helper/print_dmdfe.d) used to detect that.

5. **travis-dc-detect-slave passes the detected info, via environment variables, to a customizable reporting tool** defined in [config.sdl](https://github.com/Abscissa/travis-dc-detect-slave/blob/master/config.example.sdl). The environment variables are explained in detail in [config.example.sdl](https://github.com/Abscissa/travis-dc-detect-slave/blob/master/config.example.sdl). By default, the reporting tool is [reporter/postToHTTPS](https://github.com/Abscissa/travis-dc-detect-slave/blob/master/reporter/postToHTTPS) which HTTP(S) POSTs the data to a travis-dc-detect-master server.

6. **reporter/postToHTTPS sends the compiler information and a password from environment variables to a travis-dc-detect-master server** via HTTP(S) POST.

7. **travis-dc-detect-master validates the password** against the SHA256 hash stored in its own `config.sdl` file.

8. **travis-dc-detect-master saves the compiler's information to a MySQL/MariaDB database** if the paricular compiler version isn't already in the database.

9. **travis-dc-detect-master pre-generates an HTML page listing all the compilers and their version info.** The page is only re-generated if the compiler information is actually new.

10. **Any D user visits ... to see to current travis D compiler list with front-end version information.**
