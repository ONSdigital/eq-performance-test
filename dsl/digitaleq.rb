require 'rubygems'
require 'ruby-jmeter'


if ARGV.size != 3
  puts "      Usage: ruby digitaleq <environment> <number_of_users> <duration>"
  puts "      Please specify a target env, number of users and duration of test"
  puts "      Example:"
  puts "          ruby ruby digitaleq sprint5 10 180"
  exit 1
end

environment  = ARGV[0]
thread_count = ARGV[1].to_i
duration   = ARGV[2].to_i

puts "Executing tests on http://"+ environment +"-survey.eq.ons.digital/questionnaire/1 with "+thread_count.to_s+" users for "+duration.to_s+" seconds "

test do
  threads count: thread_count, duration: duration, continue_forever: true do
    visit name: 'Introduction', url: 'http://'+ environment +'-survey.eq.ons.digital/questionnaire/1'
        extract css: 'a.hyphenate', name: 'location'
    submit name: 'Question Page', url: '${location}',
         fill_in: {
            start: 'Proceed'
         }
    submit name: 'Complete Page', url: '${location}',
         fill_in: {
            EQ_0_1: 'Answer',
            next: 'Save and continue'
         }
  end
end.jmx
