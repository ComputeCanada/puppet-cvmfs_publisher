This puppet module configures a CVMFS publisher node using the gateway interface (https://cvmfs.readthedocs.io/en/stable/cpt-repository-gateway.html).

Here is an example content for the hieradata to configure this class: 
```
cvmfs_publisher::repositories:
  repository-name:
    repository_name: "repository name"
    repository_user: "repo-user"
    stratum0_url: "http://stratum0.url:8000/cvmfs/repository"
    gateway_url: "http://gateway.url:4929/api/v1"
    certificate: |
      -----BEGIN CERTIFICATE-----
      ...
      -----END CERTIFICATE-----
    public_key: |
      -----BEGIN PUBLIC KEY-----
      ...
      -----END PUBLIC KEY-----
    api_key: <API key>
``` 
