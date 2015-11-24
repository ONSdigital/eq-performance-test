# eq-performance-test

## Background

This repo is a suite of performance tests to be run against the survey-runner component of the EQ platform. These can either be run locally
via jmeter or vai the cloud hosted flood.io.

## How to install

 * mac osx:
	`brew install jmeter`
 * Ubuntu / Debian:
	`apt-get install jmeter`
 * Other:
 	`http://jmeter.apache.org/usermanual/get-started.html`

```
git clone https://github.com/ONSdigital/eq-performance-test.git
cd ./eq-performance-test/
bundle install
```

## Generating the Jmeter jmx file

```
cd dsl
ruby digitaleq-jmx.rb
```


## Executing on flood.io
```
ruby digitaleq-flood.rb
```
