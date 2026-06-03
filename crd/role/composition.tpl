{{- $xr   := .observed.composite.resource }}
{{- $spec := $xr.spec }}
{{- $name := $xr.metadata.name }}

{{- /* pass 1 declares the ServiceAccount requirement; pass 2 has .extraResources populated */ -}}
{{- if $spec.serviceAccountSelector }}
apiVersion: meta.gotemplating.fn.crossplane.io/v1alpha1
kind: ExtraResources
requirements:
  serviceaccounts:
    apiVersion: ldap.kubed.io/v1alpha1
    kind: ServiceAccount
    matchLabels:
    {{- range $k, $v := $spec.serviceAccountSelector.matchLabels }}
      {{ $k }}: "{{ $v }}"
    {{- end }}
---
{{- end }}

{{- /* publish status from the workspace outputs once it has reconciled */ -}}
{{- $ws := index .observed.resources "workspace" }}
{{- if and $ws $ws.resource.status.atProvider.outputs }}
apiVersion: ldap.kubed.io/v1alpha1
kind: Role
metadata:
  name: {{ $name }}
status:
  {{- with $ws.resource.status.atProvider.outputs.dn }}
  dn: {{ . }}
  {{- end }}
  {{- with $ws.resource.status.atProvider.outputs.members }}
  members: {{ . | toJson }}
  {{- end }}
  share: {{ $ws.resource.status.atProvider.outputs | toJson }}
---
{{- end }}

{{- /* assemble the authoritative member list: spec.members UNION matched SA status.dn */ -}}
{{- $members := $spec.members | default list }}
{{- if .extraResources }}
{{-   with index .extraResources "serviceaccounts" }}
{{-     range $sa := .items }}
{{-       if $sa.resource.status.dn }}
{{-         $members = append $members $sa.resource.status.dn }}
{{-       end }}
{{-     end }}
{{-   end }}
{{- end }}

{{- /* build the varmap from the common + groupofnames keys (role wires these itself) */ -}}
{{- $varmap := dict
      "name"    $name
      "base_dn" $spec.baseDn
      "owner"   $spec.owner
      "members" $members }}
{{- with $spec.description }}{{ $_ := set $varmap "description" . }}{{ end }}
{{- with $spec.seeAlso }}{{ $_ := set $varmap "see_also" . }}{{ end }}
{{- with $spec.category }}{{ $_ := set $varmap "category" . }}{{ end }}
{{- with $spec.org }}{{ $_ := set $varmap "org" . }}{{ end }}
{{- with $spec.orgUnit }}{{ $_ := set $varmap "org_unit" . }}{{ end }}
apiVersion: opentofu.upbound.io/v1beta1
kind: Workspace
metadata:
  name: {{ $name }}.roles.ldap
  annotations:
    gotemplating.fn.crossplane.io/composition-resource-name: workspace
    crossplane.io/external-name: {{ $name }}-role
spec:
  providerConfigRef:
    name: ldap
  forProvider:
    source: Remote
    module: github.com/kubed-io/terraform-ldap-components//modules/role?ref=main
    varmap: {{ $varmap | toJson }}
