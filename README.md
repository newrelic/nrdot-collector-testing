# nrdot-collector-testing

Testing utilities intended for repos related to NRDOT Collector, e.g. https://github.com/newrelic/nrdot-collector-releases

## Weaver

https://github.com/open-telemetry/weaver

Weaver is a tool used for schema management and validation.

In this chart, weaver runs as a native sidecar, initializing before the collector and telemetrygen. Running Weaver in this chart requires a minimum k8s version of `1.29`. This is because the Weaver `initContainer` requires a `restartPolicy` of `Always` to allow initialization to proceed without the container completing, a feature enabled by default in `1.29`.
