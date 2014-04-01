#Pulledpork Sandwich

Smash, and layer up that pulledpork config to support multiple sensors.

![About](http://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Germantown_Commissary%2C_BBQ_Pork_Sandwich.jpg/320px-Germantown_Commissary%2C_BBQ_Pork_Sandwich.jpg) [1]


## PREREQUISTES

* POSIX OS
* git
* Ruby ~> 1.9, 2.X 
* Perl
* Pulledpork.pl from googlecode (~> 0.6.x) (https://code.google.com/p/pulledpork)
* Valid Oinkmaster code

## INSTALL

```shell
$> git clone https://github.com/shadowbq/pulledpork_sandwich.git /opt/pulledpork_sandwich
$> cd /opt/pulledpork_sandwich
$> bundle install
```

## CONFIGURE

Create the `.\etc' dir where all your configurations will live.

`/opt/pulledpork_sandwich/etc/sandwich.conf` is the default file location.

* Copy the sandwich configuration 
* Edit/Save the sandwich.conf

```yaml
CONFIG:
  oinkcode: 123456789012345678901234567890123456789
  verbose: false
  debug: false
SENSORS:
  Sample:
    ipaddress: 10.0.0.2
    notes: "xxxxxxxx"
    hostname: sample.corp.com
  DMZ:
    ipaddress: 10.0.0.3
    notes: "DMZ Sensor"
    hostname: dmz.corp.com
``` 
 
### Note: you must have a valid oinkcode from snort.org.

An Oinkmaster Code is the unique key that is used to automate the downloading of Snort signatures from the Snort website.
The code, similar to this **"123456789012345678901234567890123456789,"** is used within pulledpork.pl to allow the download of new signatures.
An Oinkmaster Code may be obtained by logging in to the official Snort website, visiting your account settings/options page, and choosing the option to "Get a code."

## RUNTIME

```shell
$ ./bin/pulledpork_sandwich --help
Usage: pulledpork_sandwich [OPTIONS] 

Alt Modes::
    -s, --scaffold=                  scaffold a configuration for a sensor named xxx
Options::
    -n, --nopush                     Do not push / scp configurations
    -c, --config=                    location of sandwich.conf file
                                       Default: /opt/pulledpork_sandwich/etc/sandwich.conf
    -v, --verbose                    Run verbosely
    -h, --help                       Display this screen
```

Adding A New Sensor.

```shell
$> pulledpork_sandwich.rb --scaffold=Sample
$> pulledpork_sandwich .rb--nopush
```

## LICENSE

Copyright 2014 Scott MacGregor 

See LICENSE File : GNU GPLv2

[1] `CCSA - http://commons.wikimedia.org/wiki/File:Germantown_Commissary,_BBQ_Pork_Sandwich.jpg`
