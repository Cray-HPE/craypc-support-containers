# craypc support containers

These are just container images that are built and pushed manually, no pipeline for them. They are used in our Jenkins pipelines. Since we pretty much need to run all pipelines within a container on build agents, these were created. They only live under the `dtr.dev.cray.com/craypc` b/c we already have full control there as the cloud team. We could move them if/when we have some other, more sensical place to put them. My guess has continued to be that imminent pipeline changes will render alot of this obsolete anyway, but we'll see.
