# Oracle Tuxedo Service Architecture Leveraging Tuxedo (SALT) `bankapp` Sample Application

This Helm chart creates an Oracle Tuxedo  sample `bankapp` application with services sch as `INQUIRY`, `TRANSFER`, `DEPOSIT`, `WITHDRAWAL` and other similar services.

## Prerequisites

* Build a `tuxedo-bankapp` container image using the [Oracle Tuxedo bankapp image](https://github.com/oracle/docker-images/tree/main/OracleTuxedo/salt/samples/bankapp)

* Push the `tuxedo-bankapp` image that you built in the preceding step to a private container registry and note down its location. This location will be used in the `helm install` step later in this procedure.

## Using the Tuxedo `bankapp` Sample Application without Istio Ingress and SSL

* To run the `Tuxedo bankapp sample application`, install this helm chart by running the following command:

```shell
helm install \
  --set imagePullSecrets=`<your-secret-file-for-container-registry-access>` \
  --set image.repository=`<tuxedo-bankapp image location in container registry>`  \
  tuxedo-bankapp-install tuxedo/charts/tuxedo-bankapp
```

* To test the application, run the following commands to query the INQUIRY HTTP service:

```shell
export POD_NAME=$(kubectl get pods --namespace default -l "app=tuxedo-bankapp" -o jsonpath="{.items[0].metadata.name}")  # e.g. tuxbankapp-6f6569b467-gmwhx

export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")   # e.g. 5955

kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT

curl -X POST -H Content-type:application/json http://127.0.0.1:8080/INQUIRY -d '{"ACCOUNT_ID":10000}'
```

The expected output to the above `INQUIRY` HTTP request is
```json
    "ACCOUNT_ID":   10000,
    "FORMNAM":      "CBALANCE",
    "SBALANCE":     "$1456.00"
```

## Using the Tuxedo `bankapp` Sample Application with Istio Ingress and SSL

If clients external to the Kubernetes cluster should be able to access the bankapp, then you can install Istio Ingress to obtain an external IP along with SSL support.

* Install Istio `demo` profile using the [Istio Installation Guides](https://istio.io/latest/docs/setup/install/). This should result in the istio-ingressgateway service being installed, along with a valid EXTERNAL-IP value, as shown in the following sample listing:

```shell
kubectl get svc -n istio-system

    NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP 
    istio-ingressgateway   LoadBalancer   10.96.21.85     138.3.80.248
```

* Create the SSL certificates by running the following steps:

```shell
BANKAPP_SITE="bankapp.example.com"     # can be any website name (but not IP address) of your choice

# create root certificate and private key
openssl req -x509 -sha256 -nodes -days 3650 -newkey rsa:2048 -subj '/O=Example Inc/CN=does-not-matter' -keyout root-ca.private.key -out root-ca.crt

# create bankapp certificate and private key
openssl req -out bankapp.csr -newkey rsa:2048 -nodes -keyout bankapp.private.key -subj "/CN=${BANKAPP_SITE}/O=Bankapp organization"

openssl x509 -req -sha256 -days 3650 -CA root-ca.crt -CAkey root-ca.private.key -set_serial 0 -in bankapp.csr -out bankapp.crt

# create kubernetes SSL certificate secret for istio ingress gateway
kubectl create -n istio-system secret tls bankapp-credential --key=bankapp.private.key --cert=bankapp.crt

```

* To run the `Tuxedo bankapp sample application`, install this helm chart by running the following command:

```shell
helm install \
  --set imagePullSecrets=`<your-secret-file-for-container-registry-access>` \
  --set image.repository=`<tuxedo-bankapp image location in container registry>`  \
  --set EnableIngress=true \
  --set IngressTLSSecretName=`<SSL certificate secret created earlier, e.g. bankapp-credential>` \
  --set IngressTLSHosts=`<$BANKAPP_SITE used earlier, e.g. bankapp.example.com>`  \
  tuxedo-bankapp-install tuxedo/charts/tuxedo-bankapp
```

* To test the application, run the following commands to query the INQUIRY HTTP service:

```shell
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')   # e.g. 138.3.80.248

export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')  # e.g. 443
```

Go to the host from where you want to access the `bankapp` HTTP application.

Copy the root CA certificate `root-ca.crt`, which was created in one of preceding steps, to the location from you will run the below `curl` command.

```shell
export BANKAPP_SITE=<same value that was used in one of the preceding steps. e.g. bankapp.example.com.>

curl -X POST -H "Content-type:application/json" \
  -HHost:${BANKAPP_SITE} \
  --resolve "${BANKAPP_SITE}:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
  --cacert root-ca.crt \
   "https://${BANKAPP_SITE}:$SECURE_INGRESS_PORT/INQUIRY" -d '{"ACCOUNT_ID":10000}'
```

The expected output to the above `INQUIRY` HTTP request is
```json
    "ACCOUNT_ID":   10000,
    "FORMNAM":      "CBALANCE",
    "SBALANCE":     "$1456.00"
```
