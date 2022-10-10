# Oracle Tuxedo Workstation SSL server

This Helm chart creates an Oracle Tuxedo Workstation (WS) SSL server with two services: `BASICWS` and `TOUPPER`

## Prerequisites

1. Build a `tuxedows_svr` container image using the [sample Oracle Tuxedo Workstation App](https://github.com/oracle/docker-images/tree/main/OracleTuxedo/core/samples/ws_ssl_svr).

2. Upload the `tuxedows_svr` image you built in step 1 to a private container registry and take a note of its location. This location will be used in the `helm install` step later in this procedure.

3. If you want to be able to connect to the Tuxedo WS server from an external source, use the [`tuxedo-lb`](../tuxedo-lb/README.md) Helm chart to obtain an external IP address:

     ```shell
     EXT_IP=$(kubectl get service --namespace default tuxedo-loadbal-svc --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
     ```

     This IP address will provide external access to the Tuxedo services running on your Kubernetes cluster on ports 9055, 9060 and 2071 to 2075.

## Create the Tuxedo WS SSL server

To create a `Tuxedo Workstation SSL server` using this Helm chart, run:

```shell
helm install \
  --set imagePullSecrets=`<your-secret-file-for-container-registry-access>` \
  --set image.repository=`<tuxedows_svr image location in container registry>`  \
  --set TuxExternalIP="${EXT_IP}" \
  tuxedo-ws-install oracle/tuxedo-ws
```
