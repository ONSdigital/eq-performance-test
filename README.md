# eq-performance-test

## Background

This repo is a suite of performance tests to be run against the survey-runner
component of the EQ platform using JMeter. It uses ruby-jmeter to generate the
Jmeter XML definition rather than editing the XML directly or via the GUI.

## Installation
It is recommended to run Ruby with rbenv (https://github.com/rbenv/rbenv)

After installing rbenv, clone this repository and install the ruby version needed:

    rbenv install

Then install bundler (http://bundler.io/):

    gem install bundler

And install the gems needed by this project:

    bundle install

Finally install jmeter:

	brew install jmeter

## How to run

    ruby survey_runner_jmeter.rb


## Build with docker
    docker build . -t eq-performance-test


## Run with docker

    docker run \
    	-e HOST=hostname \
    	-e PROTOCOL=http \
    	-e PORT=5000 \
    	-e USERS=100 \
    	-e REPEAT=10 \
    	-v ~/testResults:/eq-performance-test/results \
       eq-performance-test

This opens JMeter with the Ruby generated .jmx file. You're ready to run the tests in JMeter now.


## Further Information
See https://github.com/flood-io/ruby-jmeter

See http://jmeter.apache.org/

### Mapping to JMeter
`ruby-jmeter` provides a simple mapping between Ruby functions and JMeter XML
elements so you can add any JMeter XML element by selecting the right Ruby
function and setting the related properties.

A quick way to do this is to look at the DSL help:

https://github.com/flood-io/ruby-jmeter/blob/master/lib/ruby-jmeter/DSL.md

Which provides a list of the JMeter elements and their Ruby function
equivalents. For example, to add a JMeter "Random Variable"
http://jmeter.apache.org/usermanual/component_reference.html#Random_Variable

The DSL.md shows this to be:

`Random Variable random_variable`

Looking at this in the DSL here:

https://github.com/flood-io/ruby-jmeter/blob/master/lib/ruby-jmeter/dsl/random_variable.rb

You can see the various properties that can be set on this in the XML:

```
@doc = Nokogiri::XML(<<-EOS.strip_heredoc)
<RandomVariableConfig guiclass="TestBeanGUI" testclass="RandomVariableConfig" testname="#{testname}" enabled="true">
  <stringProp name="maximumValue"/>
  <stringProp name="minimumValue">1</stringProp>
  <stringProp name="outputFormat"/>
  <boolProp name="perThread">false</boolProp>
  <stringProp name="randomSeed"/>
  <stringProp name="variableName"/>
</RandomVariableConfig>)
      EOS
```

e.g. `maximumValue` and `variableName`, so using this in the Ruby script would
look like:

```
    random_variable maximumValue: 10000000,
        minimumValue: 1,
        perThread: false,
        variableName: 'ru_ref'
```

This kind of approach can be used to add any JMeter XML elements to the Ruby
scripts e.g. `http_request` or `regular_expression_extractor`

See also https://github.com/flood-io/ruby-jmeter/tree/master/examples
