# redfish-https-boot

## nginx usage
To setup nginx for https boot:
1. Create self signed certs and name the public cert `cert.pem` and key `cert.key`
1. `docker run --rm -p <PORT>:443 $(docker build -q .)`