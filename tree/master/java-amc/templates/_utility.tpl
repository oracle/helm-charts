# Copyright (c) 2021, Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

{{/*
Check for Database type setting
*/}}
{{- define "amc.validatedbtype" -}}
  {{ $value := (default "" .Values.database.type | lower) }}
  {{- if or (eq $value "mysql") (eq $value "oracle") -}}
    true
  {{- end -}}
{{- end -}}

{{/*
Check if namespace for amc domain has been provided
*/}}
{{- define "amc.validatens" -}}
  {{ $value := .Values.namespace }}
  {{- if $value -}}
    true
  {{- end -}}
{{- end -}}

{{/*
If enabled, check if the SSL details are provided
*/}}
{{- define "amc.validatesslsetting" -}}
  {{- with .Values.weblogicSSLCertificateOverride -}}
    {{- if .enabled -}}
      {{- if and .configmapName .keystore.filename .keystorealias.alias -}}
        true
      {{- end -}}
    {{- else -}}
      true
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
If enabled, check if the mail server properties are provided
*/}}
{{- define "amc.validatemailsetting" -}}
  {{- if .Values.mailServer.enabled -}}
    {{- if .Values.mailServer.properties -}}
        true
    {{- end -}}
  {{- else -}}
    true
  {{- end -}}
{{- end -}}

{{/*
If enabled, check if all the LDAP settings are provided
*/}}
{{- define "amc.validateldapsetting" -}}
  {{- if .Values.ldap.enabled -}}
    {{- with .Values.ldap -}}
      {{- if and .host .principal .userbaseDN .groupbaseDN -}}
        true
      {{- end -}}
    {{- end -}}
  {{- else -}}
    true
  {{- end -}}
{{- end -}}

{{/*
Check if Database configuration values are provided
*/}}
{{- define "amc.validatedbsettings" -}}
  {{- with .Values.database -}}
    {{- if and .type .name .host .port -}}
      true
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Check if Database port value is numeric
*/}}
{{- define "amc.validatedbport" -}}
  {{- if (int .Values.database.port) }}
    true
  {{- end -}}
{{- end -}}

{{/*
Check if LDAP port value is numeric
*/}}
{{- define "amc.validateldapport" -}}
  {{- if .Values.ldap.enabled -}}
    {{- if (int (default 1 .Values.ldap.port)) }}
      true
    {{- end -}}
  {{- else -}}
    true
  {{- end -}}
{{- end -}}

{{/*
Check if AMC Docker image repository and tag are specified
*/}}
{{- define "amc.validateamcimage" -}}
  {{- with .Values.image -}}
    {{- if and .repo .tag -}}
      true
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Check if Load Balancer Port has been specified and numeric
*/}}
{{- define "amc.validatelbport" -}}
  {{- if .Values.loadBalancer.enabled  -}}
    {{- if and .Values.loadBalancer.port (int .Values.loadBalancer.port) -}}
      true
    {{- end -}}
  {{- else -}}
    true
  {{- end -}}
{{- end -}}

{{/*
Check if WebLogic Credentials are configured correctly
*/}}
{{- define "amc.validateweblogiccredentials" -}}
  {{- if or .Values.weblogicCredentials.secretsName (and .Values.weblogicCredentials.username .Values.weblogicCredentials.password) -}}
    true
  {{- end -}}
{{- end -}}

{{/*
Check if WebLogic Password conforms to the rules
*/}}
{{- define "amc.validateweblogicpassword" -}}
  {{- if and .Values.weblogicCredentials.username .Values.weblogicCredentials.password -}}
    {{- $passwd := .Values.weblogicCredentials.password }}
    {{- $length := len $passwd }}
    {{- $wordchar := regexMatch "[a-zA-Z]+" $passwd }}
    {{- $nonwordchar := regexMatch "[\\d|\\W]+" $passwd }}
    {{- if and (ge $length 8) $wordchar $nonwordchar -}}
      true
    {{- end -}}
  {{- else -}}
    true
  {{- end -}}
{{- end -}}

{{/*
Check if DataSource Credentials are configured correctly
*/}}
{{- define "amc.validatedatasourcecredentials" -}}
  {{ $output := coalesce .Values.database.credentials.secretsName .Values.database.credentials.username .Values.database.credentials.password "empty" }}
  {{- if ne "empty" $output -}}
    true
  {{- end -}}
{{- end -}}

{{/*
Check if Mail Server Credentials are configured correctly
*/}}
{{- define "amc.validatemailservercredentials" -}}
  {{- $output := "notempty" -}}
  {{- if .Values.mailServer.enabled -}}
    {{ $output = coalesce .Values.mailServer.credentials.secretsName .Values.mailServer.credentials.username .Values.mailServer.credentials.password "empty" }}
  {{- end -}}
  {{- if or (eq $output "notempty") (ne $output "empty") -}}
    true
  {{- end -}}
{{- end -}}

{{/*
Check if LDAP Credentials are configured correctly
*/}}
{{- define "amc.validateldapcredentials" -}}
  {{- $output := "notempty" -}}
  {{- if .Values.ldap.enabled -}}
    {{ $output = coalesce .Values.ldap.credentials.secretsName .Values.ldap.credentials.password "empty" }}
  {{- end -}}
  {{- if or (eq $output "notempty") (ne $output "empty") -}}
      true
  {{- end -}}
{{- end -}}

{{/*
Check if SSL Credentials are configured correctly
*/}}
{{- define "amc.validatesslcredentials" -}}
  {{- $output := "notempty" -}}
  {{- with .Values.weblogicSSLCertificateOverride -}}
    {{- if .enabled -}}
      {{- if not (and (or .keystore.secretsName .keystore.password) (or .keystorealias.secretsName .keystorealias.password)) }}
        {{- $output = "empty" }}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- if or (eq $output "notempty") (ne $output "empty") -}}
    true
  {{- end -}}
{{- end -}}

{{/*
Check if replicaCount is in expected range
*/}}
{{- define "amc.validatereplicacount" -}}
  {{- $replicas := int .Values.replicaCount }}
  {{- if and (ge $replicas 2) (le $replicas 10) }}
    true
  {{- end -}}
{{- end -}}

{{/*
Check if nodePorts are in standard range
*/}}
{{- define "amc.validatenodeportrange" -}}
  {{- if .Values.nodePort.enabled -}}
    {{- $adminPort := int (default 30000 .Values.nodePort.adminserver) }}
    {{- $managedPort := int (default 30000 .Values.nodePort.managedserver) }}
    {{- if and (ge $adminPort 30000) (le $adminPort 32767) (ge $managedPort 30000) (le $managedPort 32767)}}
      true
    {{- end -}}
  {{- else -}}
    true
  {{- end -}}
{{- end -}}

{{/*
Check if specified secrets are present in the namespace
*/}}
{{- define "amc.validatesecrets" -}}
  {{- $namespace := .Values.namespace }}
  {{- $registrysecret := true }}
  {{- $weblogicsecret := true }}
  {{- $weblogickeystoresecret := true }}
  {{- $weblogickeystorealiassecret := true }}
  {{- $datasourcesecret := true }}
  {{- $mailserversecret := true }}
  {{- $ldapserversecret := true }}

  {{- if .Values.image.pullSecrets }}
    {{- $counter := 0 }}
    {{- range $pullSecret := .Values.image.pullSecrets }}
      {{- if (lookup "v1" "Secret" $namespace $pullSecret) }}
        {{- $counter = add1 $counter }}
      {{- end }}
    {{- end -}}
    {{ $registrysecret = (eq $counter (len .Values.image.pullSecrets)) }}
  {{- end -}}

  {{- with .Values.weblogicCredentials -}}
    {{- $lookuprequired := and .secretsName (not (and .username .password)) }}
    {{- if $lookuprequired }}
      {{- $weblogicsecret = (lookup "v1" "Secret" $namespace .secretsName) }}
    {{- end -}}
  {{- end -}}

  {{- with .Values.weblogicSSLCertificateOverride -}}
    {{- $lookuprequired := and .enabled .keystore.secretsName (not .keystore.password) }}
    {{- if $lookuprequired }}
      {{- $weblogickeystoresecret = (lookup "v1" "Secret" $namespace .keystore.secretsName) }}
    {{- end -}}

    {{- $lookuprequired = and .enabled .keystorealias.secretsName (not .keystorealias.password) }}
    {{- if $lookuprequired }}
      {{- $weblogickeystorealiassecret = (lookup "v1" "Secret" $namespace .keystorealias.secretsName) }}
    {{- end -}}
  {{- end -}}

  {{- with .Values.database.credentials -}}
    {{- $lookuprequired := and .secretsName (not (and .username .password)) }}
    {{- if $lookuprequired }}
      {{- $datasourcesecret = (lookup "v1" "Secret" $namespace .secretsName) }}
    {{- end -}}
  {{- end -}}

  {{- with .Values.mailServer -}}
    {{- $lookuprequired := and .enabled .credentials.secretsName (not (and .credentials.username .credentials.password)) }}
    {{- if $lookuprequired }}
      {{- $mailserversecret = (lookup "v1" "Secret" $namespace .credentials.secretsName) }}
    {{- end -}}
  {{- end -}}

  {{- with .Values.ldap -}}
    {{- $lookuprequired := and .enabled .credentials.secretsName (not .credentials.password) }}
    {{- if $lookuprequired }}
      {{- $ldapserversecret = (lookup "v1" "Secret" $namespace .credentials.secretsName) }}
    {{- end -}}
  {{- end -}}

  {{- if and $registrysecret $weblogicsecret $weblogickeystoresecret $weblogickeystorealiassecret $datasourcesecret $mailserversecret $ldapserversecret }}
    true
  {{- end -}}
{{- end -}}
