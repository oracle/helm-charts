# Oracle Tuxedo WS (workstation) app with SSL option

Build tuxedows-svr container image using [Oracle Tuxedo WS App](https://github.com/oracle/docker-images/OracleTuxedo/core/samples/ws_ssl_svr/)

Upload the above image to a public or private container registry

Use the above location to update the "image" location in [tuxedows-svr.yaml](templates/tuxedows-svr.yaml)

If client will be connecting over external IP, then install the tuxedo-loadbal-helm-chart to obtain the external IP.

EXT_IP=<external ip to access the k8s cluster on port 9055, 9060 and 2071 to 2075 from outside the cluster>

To install this helm-chart, run the below command:

```
helm install \
  --set imagePullSecrets="`<your-secret-file-for-container-registry-access>`" \
  --set TuxLoadBalIP="${EXT_IP}" \
  tuxedows-helm-install tuxedows-helm-chart
```
