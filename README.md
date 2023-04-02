# Helm charts for Oracle products

This repository contains [Helm](https://helm.sh) charts for Oracle commercial
products.

## Available charts

* Java [Advanced Management Console](./java-amc) (AMC)
* [Oracle SOA Suite](./soa-suite/README.md)
* [Oracle Tuxedo](./tuxedo/README.md)

## Installation

To add this repository to your list of known repositories, run:

```bash
helm repo add oracle https://oracle.github.io/helm-charts
```

To install a Helm chart, run:

```bash
helm install <deployment_name> oracle/<chart_name> \
  --set <parameters>...
```

## Contributing

This project welcomes contributions from the community. Before submitting a pull
request, please [review our contribution guide](./CONTRIBUTING.md) which includes
information on how to responsibly report a security vulnerability to Oracle.

## Security

Please consult the [security guide](./SECURITY.md) for our responsible security vulnerability disclosure process

## License

Copyright (c) 2022, 2023 Oracle and/or its affiliates.

Released under the Universal Permissive License v1.0 as shown at
<https://oss.oracle.com/licenses/upl/>.
