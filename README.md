# Easx - easy Nginx with automatic Lets Encrypt 
This project is heavily inspired by [Ceryx](https://github.com/sourcelair/ceryx), 
refactored to use [Consul Catalog](https://www.hashicorp.com/blog/consul-and-external-services/) instead of Redis backend for routes. 

SSL certificates are stored in redis, but we plan to introduce support for [Vault](https://github.com/hashicorp/vault/)
and have redis as a caching layer only.

## Prerequisites
1. Docker
2. Consul
3. Redis 

## Configuration

### Add service to Consul Catalog
1. Create `example.json` file
    ```json
    {
      "Node": "easx-domains",
      "Address": "easx.domains.dev",
      "NodeMeta": {
        "external-node": "true",
        "external-probe": "true"
      },
      "Service": {
        "Service": "easx-host.example.com",
        "Tags": [
          "easx.target=https://s3.website.com/and/path",
          "easx.target_host=s3.website.com"
        ],
        "Port": 443
      },
      "Checks": [
        {
          "Name": "http-check",
          "status": "passing",
          "Definition": {
            "http": "https://host.example.com",
            "interval": "60s"
          }
        }
      ]
    }
    ```

2. Register the service with Consul 
    ```shell script
    curl --request PUT --data @example.json localhost:8500/v1/catalog/register
    ```

### Run the container with `adamjanis/easx` image (or build your own)

#### Environment variables
`EASX_LETS_ENCRYPT_STAGING` (false) use Lets Encrypt staging

`EASX_LETS_ENCRYPT_HOOK_SERVER_PORT` (8889) hook server port, 
with Nomad you might wanna use dynamic ports

`EASX_DEBUG` (false) enables DEBUG logs

`EASX_DNS_RESOLVER` (172.17.0.1)

`EASX_REDIS_PREFIX` (easx)

`EASX_REDIS_HOST` (127.0.0.1)

`EASX_REDIS_PASSWORD` ()

`EASX_REDIS_PORT` (6379)

`EASX_REDIS_TIMEOUT` (100ms)

`EASX_REDIS_SSL` (false)

`EASX_REDIS_SSL_VERIFY` (false)

`EASX_CONSUL_SERVICE_PREFIX` (easx-)

`EASX_CONSUL_HOST` (consul.service.consul)

`EASX_CONSUL_PORT` (8500)

`EASX_CONSUL_TOKEN` ()

`EASX_PROXY_DEFAULT_HOST` ($http_host)


## Known issues / todo
- Nginx running with `root` user, auto_ssl could not correctly run on `alpine-fat`
- Only proxy mode is working right now, with redirect commented out (we dont need it right now)
- Consul service needs to have both `target` and `target_host` tags set
- Tests coverage (no tests)

# Build 
-  docker build -t adamjanis/easx:dev ../ && docker push adamjanis/easx:dev && tf apply