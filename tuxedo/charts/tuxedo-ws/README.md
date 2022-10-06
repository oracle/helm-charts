# Oracle Tuxedo WS (workstation) SSL server

This helm chart creates the Tuxedo WS (workstation) SSL server with two services: `BASICWS` and `TOUPPER`

## Prerequisites

  1. Build the `tuxedows_svr` container image using the [Oracle Tuxedo WS App](https://github.com/oracle/docker-images/OracleTuxedo/core/samples/ws_ssl_svr/).

  2. Upload the container image to a private container registry. This location will be used in the `helm install` step later in this procedure.

  3. If your client will be connecting over an external IP connection, install the `loadbal` helm chart to obtain the external IP address as follows:
     ```shell
     EXT_IP=$(kubectl get service --namespace default tuxedo-loadbal-svc --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
     ```
     This IP will be used to access the tuxedo services on port 9055, 9060 and 2071 to 2075 from outside the kubernetes cluster.

## Create the Tuxedo WS SSL server

To create the `Tuxedo WS SSL server` using this Helm chart, run the following command:

```shell
helm install \
  --set imagePullSecrets=`<your-secret-file-for-container-registry-access>` \
  --set image.repository=`<tuxedows_svr image location in container registry>`  \
  --set TuxExternalIP="${EXT_IP}" \
  tuxedo-ws-helm-install tuxedo/charts/tuxedo-ws
```

