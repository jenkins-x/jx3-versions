## Helm values files and templates

These files are added to the `helmfile.yaml` by default to add extra configuration to the helm charts.

The file layout is either:

* `[repositoryPrefix]/chartName/values.yaml` the `values.yaml` which should be added to the helm command via `--values` argument
* `[repositoryPrefix]/chartName/values.yaml.gotmpl` a go template which is rendered by `helmfile` into a `values.yaml` which will be added to the helm command via `--values` argument

e.g.

* [jenkins-x](jenkins-x)/[tekton](jenkins-x/tekton)/[values.yaml.gotmpl](jenkins-x/tekton/values.yaml.gotmpl)


The mapping of repository prefixes to URLs is specified in the [../charts/repositories.yml](../charts/repositories.yml) file