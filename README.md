#Pulledpork Sandwich

Smash, and layer up that pulledpork config to support multiple sensors.

![About](http://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Germantown_Commissary%2C_BBQ_Pork_Sandwich.jpg/320px-Germantown_Commissary%2C_BBQ_Pork_Sandwich.jpg) [1]


## PREREQUISTES

* POSIX OS
* git
* Ruby ~> 1.9, 2.X with bundler gem
* Perl
* Pulledpork.pl from googlecode (~> 0.7.x) (https://code.google.com/p/pulledpork)
* Valid Oinkmaster code

## INSTALL

```shell
$> git clone https://github.com/shadowbq/pulledpork_sandwich.git /opt/pulledpork_sandwich
$> cd /opt/pulledpork_sandwich
$> sudo ln -s /opt/pulledpork_sandwich/bin/pulledpork /usr/bin/pulledpork_sandwich
$> bundle install
```

## CONFIGURE

Create the `./etc` dir where all your configurations will live.

`/opt/pulledpork_sandwich/etc/sandwich.conf` is the default file location for the configuration file.

* Copy the sandwich configuration from the `defaults` directory
* Edit/Save the sandwich.conf

```yaml
CONFIG:
  oinkcode: 123456789012345678901234567890123456789
  verbose: false
  debug: false
  pulledpork:
    rules-urls:
      opensource:
        url: https://www.snort.org/reg-rules/|opensource.gz
        oinkcode: true
      vrt-rules:
        url: https://www.snort.org/reg-rules/|snortrules-snapshot.tar.gz
        oinkcode: true
      community:
        url: https://s3.amazonaws.com/snort-org/www/rules/community/|community-rules.tar.gz
    ipblacklists:
      - http://labs.snort.org/feeds/ip-filter.blf
    # Note that setting this value will disable all non-label rulesets (ET, etc)  
    # ruleset: security
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
Deployment Modes::
    -n, --nopush                     Do not push via scp the new packages
                                       Default: false

Options::
    -k, --keep                       Keep existing rules, aka do not download new rules from rules sources
                                       Default: false
    -c, --config=                    Location of sandwich.conf file
                                       Default: /opt/pulledpork_sandwich/etc/sandwich.conf
    -v, --verbose                    Run verbosely

Alt Modes::
    -s, --scaffold=                  scaffold a configuration for a sensor named xxx
        --purge                      Delete all logs, tmps
        --clobber                    Delete all logs, tmps, archives, and exports
    -h, --help                       Display this screen
```

Adding A New Sensor.

```shell
$> pulledpork_sandwich --scaffold=Sample
```

Running in verbose mode. (See #Logs)

```shell
$> pulledpork_sandwich --nopush -v -k 
Sensor - Sample :m.p.r.z.done
```

## TUNE

Edit the `etc\global.*.conf` files if you want to affect all the sensors.

Edit the `etc\sensors\<named>\*.conf` files if you want to affect a specific sensor.

Please read the pulledpork documentation on googlecode for instructions on how write the conf files.

Examples: 

* [Enable SID](https://pulledpork.googlecode.com/svn/trunk/etc/enablesid.conf)
* [Drop SID](https://pulledpork.googlecode.com/svn/trunk/etc/dropsid.conf)
* [Disable SID](https://pulledpork.googlecode.com/svn/trunk/etc/disablesid.conf)
* [Modify SID](https://pulledpork.googlecode.com/svn/trunk/etc/modifysid.conf)

### Order of Operations

Please note that pulledpork runs rule modification **(enable, drop, disable, modify)** in that order by default..

### Threshold - Event Processing

Pulled Pork Sandwich also includes the snort `threshold.conf` in a similar global/local fashion. Sandwich will automagically merge any needed threshold file
and allow you to maintain a single location for event processing. 

* [Snort Manual - Node 19 - Event Processing](http://manual.snort.org/node19.html)

Filter Type | Description
--- | ---
Rate Filters |  You can use rate filters to change a rule action when the number or rate of events indicates a possible attack.
Event Filters | You can use event filters to reduce the number of logged events for noisy rules. This can be tuned to significantly reduce false alarms.
Event Suppression | You can completely suppress the logging of uninteresting events.

## LOGS

Logfiles are very useful. Not so much when they fill my STDOUT screen. 

* They live in ./log 
* Each Sensor has its name pre-appended to the log filename.
* All logs have an epoch UTC timestamp attached prior to its extension.
* Pulledpork runs in verbose and the STDOUT & STDERR are stored. 

## LICENSE

Copyright 2014 - Scott MacGregor 

See [LICENSE File](./LICENSE) : GNU GPLv2

[1] `CCSA - http://commons.wikimedia.org/wiki/File:Germantown_Commissary,_BBQ_Pork_Sandwich.jpg`
