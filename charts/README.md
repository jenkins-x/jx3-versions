## Charts

This directory tree contains the version of helm charts used by default if no explicit version is specified in your `helmfile.yaml` file.

The file layout is `[repositoryPrefix]/chartName.yml` with the YAML file containing a `version:` property 

e.g.

* [jenkins-x](jenkins-x)/[tekton.yml](jenkins-x/tekton.yml)

The mapping of repository prefixes to URLs is specified in the [repositories.yml](repositories.yml) file