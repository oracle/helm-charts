# Copyright (c) 2021, Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

{{- define "amc.datasource" -}}
{{- $dbtype := .Values.database.type | lower }}
{{- if eq "mysql" $dbtype -}}
  jdbc:mysql://{{ .Values.database.host }}:{{ .Values.database.port }}/{{ .Values.database.name }}
{{- else if eq "oracle" $dbtype -}}
  jdbc:oracle:thin:@{{ .Values.database.host }}:{{ .Values.database.port }}/{{ .Values.database.name }}
{{- end }}
{{- end -}}

{{/*
Return the secrets name based on type
*/}}
{{- define "amc.getsecretsname" -}}
{{- $domainname := include "amc.domainname" .root }}
{{- if eq "datasource" .type -}}
{{ .root.Values.database.credentials.secretsName | default (print $domainname "-datasource-credentials") }}
{{- else if eq "weblogic" .type -}}
{{ .root.Values.weblogicCredentials.secretsName | default (print $domainname "-weblogic-credentials") }}
{{- else if eq "weblogic-keystore" .type -}}
{{ .root.Values.weblogicSSLCertificateOverride.keystore.secretsName | default (print $domainname "-weblogic-keystore-credentials") }}
{{- else if eq "weblogic-alias" .type -}}
{{ .root.Values.weblogicSSLCertificateOverride.keystorealias.secretsName | default (print $domainname "-weblogic-keystorealias-credentials") }}
{{- else if eq "mailserver" .type -}}
{{ .root.Values.mailServer.credentials.secretsName | default (print $domainname "-mailserver-credentials") }}
{{- else if eq "ldap" .type -}}
{{ .root.Values.ldap.credentials.secretsName | default (print $domainname "-ldap-credentials") }}
{{- end -}}
{{- end -}}

{{/*
Return a runtime encryption secret with randomness
*/}}
{{- define "amc.runtimesecret" -}}
{{- printf "%s-%s" (include "amc.domainname" .) (randAlphaNum 32) -}}
{{- end -}}

{{/*
Target cluster for the Database resource in model
*/}}
{{- define "amc.targetcluster" -}}
{{- $dbtype := .Values.database.type | lower }}
{{- if eq .dbresource $dbtype }}
Target: {{ include "amc.clustername" . | quote }}
{{- else }}
Target: ''
{{- end -}}
{{- end -}}

{{/*
JDBC URL for the Database resouce in model
*/}}
{{- define "amc.targeturl" -}}
{{- $dbtype := .Values.database.type | lower }}
{{- if eq .dbresource $dbtype }}
URL: {{ include "amc.datasource" . | quote }}
{{- else }}
URL: ''
{{- end -}}
{{- end -}}

{{/*
Set JDNI for the Oracle database
*/}}
{{- define "amc.oraclejndi" -}}
{{- if .Values.database.isOracle11 }}
JNDIName: amc2/db/oracle11
{{- else }}
JNDIName: amc2/db/oracle
{{- end -}}
{{- end -}}

{{/*
Toggle JDBC Driver for MySQL
*/}}
{{- define "amc.jdbcdriver" -}}
{{- if .Values.database.use_cj_driver_mysql8 }}
DriverName: com.mysql.cj.jdbc.Driver
{{- else }}
DriverName: com.mysql.jdbc.Driver
{{- end -}}
{{- end -}}

{{/*
Setup a Kubernetes node port for the administration server default channel
*/}}
{{- define "amc.nodeportadmin" -}}
{{- if .Values.nodePort.enabled }}
adminService:
  channels:
  - channelName: default
    nodePort: {{ default 0 .Values.nodePort.adminserver }}
{{- end -}}
{{- end -}}

{{/*
Return domain name for AMC deployment
*/}}
{{- define "amc.domainname" -}}
{{- $domain := default "amc-domain" .Values.domain -}}
{{- printf "%s" $domain -}}
{{- end -}}

{{/*
Return cluster name for AMC deployment
*/}}
{{- define "amc.clustername" -}}
{{- $cluster := default "amc-cluster" .Values.clusterName -}}
{{- printf "%s" $cluster -}}
{{- end -}}

{{/*
Setup the Secrets that contain the credentials for pulling an image
*/}}
{{- define "amc.imagepullsecret" -}}
{{- if .Values.image.pullSecrets }}
imagePullSecrets:
{{- range $pullSecret := .Values.image.pullSecrets }}
  - name: {{ $pullSecret }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Setup the Secrets for domain configuration
*/}}
{{- define "amc.configsecrets" -}}
{{- $domain := include "amc.domainname" . }}
{{- $listOfSecrets := list (include "amc.getsecretsname" (dict "root" . "type" "datasource")) -}}
{{- if .Values.ldap.enabled -}}
  {{- $listOfSecrets = append $listOfSecrets (include "amc.getsecretsname" (dict "root" . "type" "ldap")) -}}
{{- end -}}
{{- if .Values.mailServer.enabled -}}
  {{- $listOfSecrets = append $listOfSecrets (include "amc.getsecretsname" (dict "root" . "type" "mailserver")) -}}
{{- end }}
{{- if .Values.weblogicSSLCertificateOverride.enabled -}}
  {{- $listOfSecrets = append $listOfSecrets (include "amc.getsecretsname" (dict "root" . "type" "weblogic-keystore")) -}}
  {{- $listOfSecrets = append $listOfSecrets (include "amc.getsecretsname" (dict "root" . "type" "weblogic-alias")) -}}
{{- end }}

{{- $listOfSecrets = $listOfSecrets | uniq -}}
{{- range $listOfSecrets }}
- {{.}} 
{{- end -}}
{{- end -}}

{{/*
Set the environment variables for server pods
*/}}
{{- define "amc.serverenv" -}}

{{- $defaultjavaopt := "-Dweblogic.StdoutDebugEnabled=false" }}
{{- $defaultuseropt := "-XX:+UseContainerSupport" }}

{{- range $key, $value := .args }}
{{- $finalvalue := "" }}
{{- if eq $key "JAVA_OPTIONS" }}
{{- $finalvalue = cat $defaultjavaopt $value }}
{{- else if eq $key "USER_MEM_ARGS" }}
{{- $finalvalue = cat $defaultuseropt $value }}
{{- end }}
- name: {{ $key }}
  value: "{{ $finalvalue }}"
{{- end }}

- name: AMC-CLUSTER-NAME
  value: {{ template "amc.clustername" .root }}
{{- end -}}

{{/*
Set the pod refresh factor
*/}}
{{- define "amc.unavailablecount" -}}
{{- $value := 1 }}
{{- if .Values.isVersionUpgrade -}}
  {{- $value = .Values.replicaCount }}
{{- end -}}
{{ print $value }}
{{- end -}}

{{/*
WebLogic volume mount setting
*/}}
{{- define "amc.volumemounts" -}}
{{- $domain := include "amc.domainname" . }}
{{- with .Values.weblogicSSLCertificateOverride -}}
{{- if .enabled }}
volumeMounts:
  - name: config
    mountPath: "/u01/customkeystore"
    readOnly: true
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
WebLogic volume setting
*/}}
{{- define "amc.volumes" -}}
{{- with .Values.weblogicSSLCertificateOverride -}}
{{- if .enabled }}
volumes:
  - name: config
    configMap:
      name: {{ .configmapName }}
      items:
      - key: {{ .keystore.filename }}
        path: {{ .keystore.filename }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
WebLogic KeyStore settings
*/}}
{{- define "amc.keystoresettings" -}}
{{- $secretname := include "amc.getsecretsname" (dict "root" . "type" "weblogic-keystore") -}}
{{- with .Values.weblogicSSLCertificateOverride -}}
{{- if .enabled }}
CustomIdentityKeyStoreFileName: "/u01/customkeystore/{{ .keystore.filename }}"
KeyStores: CustomIdentityAndJavaStandardTrust
CustomIdentityKeyStoreType: JKS
CustomTrustKeyStoreType: JKS
CustomIdentityKeyStorePassPhraseEncrypted: '@@SECRET:{{ $secretname }}:password@@'
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
WebLogic SSL settings
*/}}
{{- define "amc.sslsettings" -}}
{{- $secretname := include "amc.getsecretsname" (dict "root" . "type" "weblogic-alias") -}}
{{- with .Values.weblogicSSLCertificateOverride -}}
{{- if .enabled }}
ServerPrivateKeyPassPhraseEncrypted: '@@SECRET:{{ $secretname }}:password@@'
ServerPrivateKeyAlias: {{ .keystorealias.alias }}
UseServerCerts: true
SSLRejectionLoggingEnabled: true
AllowUnencryptedNullCipher: false
InboundCertificateValidation: 'BuiltinSSLValidationOnly'
OutboundCertificateValidation: 'BuiltinSSLValidationOnly'
HostnameVerificationIgnored: false
ClientCertificateEnforced: false
JSSEEnabled: true
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Calculate sha256 hash for the configuration. This decides
in an introspection is required
*/}}
{{- define "amc.hashforintrospection" -}}
{{- $value := tpl (.Files.Get "model/amc-model.yaml") . }}
{{- cat $value .Values.weblogicCredentials.secretsName .Values.weblogicCredentials.username .Values.weblogicCredentials.password .Values.weblogicSSLCertificateOverride.keystore.password .Values.weblogicSSLCertificateOverride.keystorealias.password .Values.database.credentials.username .Values.database.credentials.password .Values.mailServer.credentials.username .Values.mailServer.credentials.password .Values.ldap.credentials.password | sha256sum | trunc 63 | quote }}
{{- end -}}
