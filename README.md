#Pulledpork Sandwich

[![Tags](https://img.shields.io/github/tag/shadowbq/pulledpork_sandwich.svg)](https://github.com/shadowbq/pulledpork_sandwich/releases)

Managing mulitple IDS sensor policies for an enterprise deployment can be difficult, whether it be SNORT, SURICATA, or SAGAN. If you have a single sensor, or similiar networks you can use a single policy for your IDS sensors. Using the traditional `pulledpork.pl` can assist you in fetching and modifing this policy. Over time, pruning and tuning becomes difficult to manage when you have more than one network and mulitple types of network traffic (VOIP vs BROADCAST vs traditional desktop). 

Commercial solutions for some time have allowed for an order of precedence for default rules to run from the lowest context to the highest. `Pulledpork_sandwich` attempts to provide an hierarchical policy layering environment where settings edited at the lowest sensor level are allowed to override settings at the global level. This ability allows for tuning of thresholds, disabling of signatures, and regex signature modifications to happen at the most specific point.

Smash, and layer up that pulledpork config to support multiple sensors!

![About](http://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Germantown_Commissary%2C_BBQ_Pork_Sandwich.jpg/320px-Germantown_Commissary%2C_BBQ_Pork_Sandwich.jpg) [1]


## PREREQUISTES

* POSIX OS
* git
* Ruby ~> 1.9, 2.X with bundler gem
* Perl 
 * cpan install LWP::UserAgent
 * cpan install Crypt::SSLeay
* Pulledpork.pl 
  * shirkdog/pulledpork github (-> v0.7.1 +) 
  * Old from googlecode (-> v0.7.0) (https://code.google.com/p/pulledpork)   (https://pulledpork.googlecode.com/svn-history/r268/trunk/pulledpork.pl)
* Valid Oinkmaster code

## INSTALL

```shell
$> git clone https://github.com/shadowbq/pulledpork_sandwich.git /opt/pulledpork_sandwich
$> cd /opt/pulledpork_sandwich
$> sudo ln -s /opt/pulledpork_sandwich/bin/pulledpork_sandwich /usr/bin/pulledpork_sandwich
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
        url: https://snort.org/downloads/community/|community-rules.tar.gz|Community
        explicit: true
    ip-blacklists:
      - http://talosintel.com/feeds/ip-filter.blf
    path: /opt/bin/pulledpork.pl
    version: 0.7.1
    # Note that setting this value will disable all non-label rulesets (ET, etc)  
    # ruleset: security
SENSORS:
  Sample:
    ipaddress: 10.0.0.2
    notes: "xxxxxxxx"
    hostname: sample.corp.com
    distro: FreeBSD-8.1
    snort_version: 2.9.7.6
  DMZ:
    ipaddress: 10.0.0.3
    notes: "DMZ Sensor"
    hostname: dmz.corp.com
    distro: FreeBSD-8.1
    snort_version: 2.9.7.6

``` 
 
### Note: you must have a valid oinkcode from snort.org.

An Oinkmaster Code is the unique key that is used to automate the downloading of Snort signatures from the Snort website.
The code, similar to this **"123456789012345678901234567890123456789,"** is used within pulledpork.pl to allow the download of new signatures.

An Oinkmaster Code may be obtained by logging in to the official Snort website, visiting your account settings/options page, and choosing the option to "Get a code."

## RUNTIME

```shell
Usage: pulledpork_sandwich [OPTIONS]

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
    -g, --global-only                Only run pulledpork_sandwich for global configuration
        --purge                      Deletes log, tmp
        --clobber                    Deletes log, tmp, archive, and export
    -h, --help                       Display this screen
```

## Adding A New Sensor.

Each sensors and its configuration must be added to the `sandwich.conf` file in YAML format. 

```yaml
DMZ:
    ipaddress: 10.0.0.3
    notes: "DMZ Sensor"
    hostname: dmz.corp.com
    distro: FreeBSD-8.1
    snort_version: 2.9.7.6
```    

Once you have added the correct stanza in the configuration file, you can scaffold the directories and configurations by running the follow command:

```shell
$> pulledpork_sandwich --scaffold=DMZ
```

## Policy Layering

`pulledpork.pl` does not support threshold configuration changes, but `pulledpork_sandwich` does support the layering and distribution of threshold files.

### TUNING

Edit the `etc\global.*.conf` files if you want to affect all the sensors.

Edit the `etc\sensors\<named>\*.conf` files if you want to affect a specific sensor.

Please read the pulledpork documentation on googlecode for instructions on how write the conf files.

Examples: 

* [Enable SID](https://pulledpork.googlecode.com/svn/trunk/etc/enablesid.conf)
* [Drop SID](https://pulledpork.googlecode.com/svn/trunk/etc/dropsid.conf)
* [Disable SID](https://pulledpork.googlecode.com/svn/trunk/etc/disablesid.conf)
* [Modify SID](https://pulledpork.googlecode.com/svn/trunk/etc/modifysid.conf)

### Global

The global configuration layer is built everytime a new policy is built. The global policy layer can be tested and built without all the sensor policy layers for testing or exportation to a index system like SNORBY. 

When running the global only build,  `etc\global.*.conf` only are used in combination with pulledpork to create the `export\global\*` files.

## Advanced Runtime Options

Having problems with your path? Run from `/opt/pulledpork_sandwich`

```shell
$> cd /opt/pulledpork_sandwich/
$> ./bin/pulledpork_sandwich --options --more-option-examples
```

Skipping SSL Hostname Validation (pulledpork.pl ENV)

```shell
$> PERL_LWP_SSL_VERIFY_HOSTNAME=0 ./bin/pulledpork_sandwich -n -v
```

Running in verbose mode. (See #Logs)

```shell
$> pulledpork_sandwich --nopush -v -k 
Sensor - Sample :m.p.r.z.done
```


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

## IP Blacklists

```yaml
CONFIG:
    ip-blacklists:
      - http://labs.snort.org/feeds/ip-filter.blf
      - http://malc0de.com/bl/IP_Blacklist.txt
      - http://www.malwaredomainlist.com/hostslist/ip.txt
```

As defined above, you can add as many IP Blacklists in you want. 

The output will be saved into each sensor's export and package tarball as the `combined.blacklist` file. 

The `combined.IPRVersion.dat` is also included which is a modified MD5 Hash of the href


## LOGS

Logfiles are very useful. Not so much when they fill my STDOUT screen. 

* They live in ./log 
* Each Sensor has its name pre-appended to the log filename.
* All logs have an epoch UTC timestamp attached prior to its extension.
* Pulledpork runs in verbose and the STDOUT & STDERR are stored. 


## DIRECTORY TREE

Example of the directory tree after successfully scaffolding the Sample sensor
and then running `pulledpork_sandwich` on a copied default `sandwich.conf`. 

```Shell
.
├── archive
│   ├── global_package.1397521079.tgz
│   └── Sample_package.1397421075.tgz
├── bin
│   └── pulledpork_sandwich
├── defaults
│   ├── global.disablesid.conf
│   ├── global.dropsid.conf
│   ├── global.enablesid.conf
│   ├── global.localrules.conf
│   ├── global.modifysid.conf
│   ├── global.threshold.conf
│   ├── sandwich.conf.example
│   ├── sensors
│   │   └── Sample
│   │       ├── disablesid.conf
│   │       ├── dropsid.conf
│   │       ├── enablesid.conf
│   │       ├── localrules.conf
│   │       ├── modifysid.conf
│   │       └── threshold.conf
│   └── snort.conf.example
├── etc
│   ├── global.disablesid.conf
│   ├── global.pulledpork.conf
│   ├── global.dropsid.conf
│   ├── global.enablesid.conf
│   ├── global.localrules.conf
│   ├── global.modifysid.conf
│   ├── global.threshold.conf
│   ├── sandwich.conf
│   ├── sensors
│   │   └── Sample
│   │       ├── combined
│   │       │   ├── disablesid.conf
│   │       │   ├── dropsid.conf
│   │       │   ├── enablesid.conf
│   │       │   ├── localrules.conf
│   │       │   ├── modifysid.conf
│   │       │   └── threshold.conf
│   │       ├── disablesid.conf
│   │       ├── dropsid.conf
│   │       ├── enablesid.conf
│   │       ├── localrules.conf
│   │       ├── modifysid.conf
│   │       ├── pulledpork.dyn.conf
│   │       └── threshold.conf
│   └── snort.conf
├── export
|   └── global
│       ├── sid-msg.map
│       ├── snort.rules
│       └── threshold.conf
│   └── sensors
│       ├── Sample
│       │   ├── sid-msg.map
│       │   ├── snort.rules
│       │   └── threshold.conf
│       └── SAMPLE_package.1397421075.tgz
├── Gemfile
├── Gemfile.lock
├── lib
│   ├── pulledpork_sandwich
│   │   ├── cli.rb
│   │   ├── sandwich_conf.rb
│   │   ├── sandwich.rb
│   │   ├── sandwich_wrapper.rb
│   │   ├── sensor_collection.rb
│   │   └── sensor.rb
│   └── pulledpork_sandwich.rb
├── LICENSE
├── log
│   ├── Sample_pulledpork.1397421075.err
│   ├── Sample_pulledpork.1397421075.log
│   └── Sample_sid_changes.1397421075.log
├── README.md
├── tmp
│   ├── community-rules.tar.gz
│   ├── community-rules.tar.gz.md5
│   ├── opensource.gz
│   ├── opensource.gz.md5
│   ├── snortrules-snapshot-2923.tar.gz
│   └── snortrules-snapshot-2923.tar.gz.md5

```

### Generally GEN1 Accepted SID Ranges
SourceFire / Snort.org: 

* If the number is less than 1000000, it is a SourceFire rule 
* 1-3464 Old Snort GPL sigs (moved to the 2100000 sid range ) 

Local Rules:

* 1000000-1999999 Reserved for Local Use -- Put your custom rules in this range to avoid conflicts

Emergin Threats:

* 2000000-2099999 Emerging Threats Open Rulesets
* 2100000-2103999 Forked ET Versions of the Original Snort GPL Signatures Originally sids 3464 and prior, forked to be maintained

Converted to Suricata:

* 2200000-2200999 Suricata Decoder Events
* 2210000-2210999 Suricata Stream Events
* 2220000-2299999 Suricata Reserved
* 2800000-2809999 Emerging Threats Pro Full Coverage Ruleset -- ETProRules

Dynamicly Updated Rules:

* 2400000-2400999 SpamHaus DROP List — Updated Daily -- SpamHausDROPList
* 2402000-2402299 Dshield Top Attackers Rules — Updated Daily -- DshieldTopAttackers
* 2403300-2403499 CIArmy.com Top Attackers Rules — Updated Daily - See http://www.ciarmy.com#list -- CiArmy?
* 2404000-2404299 Shadowserver.org Bot C&C List — Updated Daily -- BotCC
* 2405000-2405999 Shadowserver.org Bot C&C List Grouped by Port — Updated Daily -- BotCC
* 2406000-2406999 Russian Business Network Known Nets --- OBSOLETED -- RussianBusinessNetwork
* 2408000-2408499 Russian Business Network Known Malvertisers --- OBSOLETED -- RussianBusinessNetwork
* 2520000-2521999 Tor Exit Nodes List Updated Daily -- TorRules
* 2522000-2525999 Tor Relay Nodes List (NOT Exit nodes) Updated Daily -- TorRules

[Generally Accepted SID Ranges](http://doc.emergingthreats.net/bin/view/Main/SidAllocation)

## SNORT.ORG (The Talos Group) - EOL POLICY

It's important to understand the EOL policy of the Cisco TALOS group, and what signatures they support. 

https://snort.org/eol

Ensure your version of snort listed in `sandwich.conf` is under support. 

``` 
snort_version: 2.9.7.0 
```

## LICENSE

Copyright 2014 - Scott MacGregor 

See [LICENSE File](./LICENSE) : GNU GPLv2

[1] `CCSA - http://commons.wikimedia.org/wiki/File:Germantown_Commissary,_BBQ_Pork_Sandwich.jpg`
