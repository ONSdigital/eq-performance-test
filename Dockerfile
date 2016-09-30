FROM ruby:2

RUN apt-get update; \
    apt-get install -y jmeter

ADD Gemfile* /eq-performance-test/

WORKDIR /eq-performance-test

RUN bundle install

ADD * /eq-performance-test/

RUN touch jmeter.log

VOLUME /eq-performance-test/results

CMD ruby survey_runner_jmeter.rb