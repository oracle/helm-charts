# Oracle Tuxedo LoadBalancer service

This service provides client access to the Tuxedo Workstation (WS) service from an external IP address.

The `LoadBalancer` service must be running before deploying Tuxedo WS server using the `tuxedo-ws` Helm chart.

To create a `LoadBalancer` using this Helm chart, run:

```shell
helm install tuxedo-lb-install oracle/tuxedo-lb
```
