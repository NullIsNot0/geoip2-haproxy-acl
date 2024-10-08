# geoip2-haproxy-acl

GeoIP2 country blocking with HAProxy.

Downloads GeoLite2 country csv and splits it into per-country files. Output is
compatible with HAProxy ACL (Access Control Lists).

```
./subnets
 |- AD.txt
 |- AE.txt
 |- ...
 |- CN.txt
 |- ...
 |- US.txt
 |- ...
 |- ZM.txt
 |- ZW.txt  
```

## Usage

### MaxMind License Key

Since 2020, MaxMind now requires a registration in order to download free GeoIP2 databases.

Register at maxmind.com, go to "My account" -> "My License Keys" and generate a new license key.

### Pull latest GeoIP2 data
```
git clone https://github.com/Hypernova-Oy/geoip2-haproxy-acl.git
cd geoip2-haproxy-acl
mkdir -p /etc/haproxy/geoip2
./generate.sh --license YOUR_MAXMIND_ACCOUNT_ID:YOUR_MAXMIND_FREE_LICENSE_KEY --output-directory /etc/haproxy/geoip2 --separate-anonymous-proxies
```

This script generates a directory `subnets` under project root if `--output-directory` is not specified.  
Use option `--separate-anonymous-proxies` if you wish to save anonymous proxies endpoints into separate list.

### Add ACL to HAProxy
```
acl acl_CN src -f /etc/haproxy/geoip2/CN.txt
acl acl_US src -f /etc/haproxy/geoip2/US.txt

http-request deny if !acl_CN
http-request deny if !acl_US
```

The above example rejects connections from China and the United States.

### Cron

GeoLite2 Country database is [updated weekly, every Tuesday](https://dev.maxmind.com/geoip/geoip2/geolite2/).

Add the following cronjob if you wish to stay up to date (replace `/path/to/`
with your script path). It pulls latest updates every Wednesday at 06:00 AM.

``
0 6 * * 3 bash -c '/path/to/geoip2-haproxy-acl/generate.sh --license YOUR_MAXMIND_ACCOUNT_ID:YOUR_MAXMIND_FREE_LICENSE_KEY --output-directory /etc/haproxy/geoip2 && /bin/systemctl reload haproxy'
``

## License

See [LICENSE](LICENSE).
