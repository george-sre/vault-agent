# vault-agent

`vault-agent` is a system for projecting secrets from Vault into Kubernetes secrets.

# Environment Variables

`vault-agent` is primarily configured by environment variables.

| Variable  | Default  | Description |
|---|---|---|
| VAULT_TOKEN | _required_ | Vault token |
| VAULT_ADDR | _required_ | Vault URL |
| PROJECT | *from metadata* | Project (tree) to use for secrets |
| LOG_LEVEL | INFO | Logging level |
| SECRET_REFRESH_TIME | 300 | How often to refresh secrets |
| IGNORE_NAMESPACES | "default,kube-system,kube-public" | Namespaces to never populate |
| APP_CONFIG_MAP | vault-agent.app-config | Config map for per-namespace overrides |
| SECRET_BASE_PATH | secret | Base path in Vault where secrets are rooted |
| SECRET_NAME_SUFFIX | .service-secrets | Suffix appended to the app name's secrets object |
| K8S_SKIP_TLS_VERIFY | "" | Skips verification of Kubernetes API TLS.  Needed for Aliyun. |

# `vault-agent.app-config` and namespaces

The APP_CONFIG_MAP variable defines a ConfigMap that may be present in each namespace to control which service's secrets are included.

It must contain one key `apps`, which should be formatted as a YAML list:
```
- app1
- app2
```

## The Rules
* For expediency, a single app or the keyword "ALL" may be listed as a bare word, without the leading "-".
* The keyword "ALL" is special, and will include the secrets for every service that has default or namespace-specific entries for the current namespace.  If "ALL" is listed in addition to specific services, "ALL" takes precedence.
* The absence of the APP_CONFIG_MAP map in a namespace implies "ALL" services will be included within that namespace.
* Namespaces in the IGNORE_NAMESPACES list never recieve any secrets from `vault-agent`, regardless of any ConfigMap.

# Development

Use the "script/" directory to set up a local development enviromment.

* delete any minikube environment with `minikube delete`.  vault-agent is very sensitive to existing information, and tests can become confusing with stale secrets.
* run `./script/setup` to set up the minikube and Vault environment.
* run `./script/seed` to add some basic seed data.
* run `./script/run` to build the vault-agent container and execute it.

# Testing

Automated testing is still on the TODO list, but you can verify correct behavior of the test setup.

`kubectl get secret --all-namespaces | grep service-secrets` should yield something that looks like:
```
all-apps      bar.service-secrets               Opaque                                2         19m
all-apps      foo.service-secrets               Opaque                                1         19m
foo           foo.service-secrets               Opaque                                1         19m
ops           baz.service-secrets               Opaque                                1         19m
stable        bar.service-secrets               Opaque                                2         19m
stable        foo.service-secrets               Opaque                                1         19m
wrong         bar.service-secrets               Opaque                                2         19m
wrong         foo.service-secrets               Opaque                                1         19m
```

Each section demonstrates a particular case.
* *all-apps* has a ConfigMap that includes "ALL" services
* *foo* has a ConfigMap that includes only the foo service (as a bareword)
* *ops* has a ConfigMap that includes only the baz service (as a YAML list)
* *stable* has _no_ ConfigMap, and defaults to "ALL" services
* *wrong* has a confusing ConfigMap, including "baz" (which it cannot find values for) and "ALL", which overrides "baz"

Note: the "baz" service has values for only the "ops" namespace, its absence in the other namespaces is an important test.  Also, the absence of secrets in the excluded "default" namespace is another important omission test.
