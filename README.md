# eq-performance-test

## Background

This repo is a suite of performance tests to be run against the survey-runner component of the EQ platform using JMeter

## How to install

	`brew install jmeter`

## Getting the token

You will need the survey runner repo for token generation

```
git clone https://github.com/ONSdigital/eq-survey-runner.git
cd ./eq-survey-runner/
python token_generator.py
```

## How to run

```
Open JMeter and open Survey-runner.jmx in the application
Insert the token generated in the decode http request
Your ready to run the tests
```