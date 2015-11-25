require 'rubygems'
require 'ruby-jmeter'


if ARGV.size != 4
  puts "      Usage: ruby digitaleq <environment> <number_of_users> <duration> <flood_api_key>"
  puts "      Please specify a target env, number of users and duration of test"
  puts "      Example:"
  puts "          ruby ruby digitaleq sprint5 10 180 i2rPa4C2_gZCKerGahUD"
  exit 1
end

environment  = ARGV[0]
thread_count = ARGV[1].to_i
duration   = ARGV[2].to_i
flood_api = ARGV[3]

puts "Executing tests on http://"+ environment +"-survey.eq.ons.digital/questionnaire/1 with "+thread_count.to_s+" users for "+duration.to_s+" seconds "

test do
  threads count: thread_count, duration: duration, continue_forever: true do
    visit name: 'Introduction', url: 'http://'+ environment +'-survey.eq.ons.digital/questionnaire/1?debug=True'
        extract css: 'a.hyphenate', name: 'location'
    submit name: 'Intro Page', url: '${location}',
         fill_in: {
            start: 'Proceed'
         }
    submit name: 'Section 1', url: '${location}',
         fill_in: {
            EQ_sectionOne_q2: 'Han',
            EQ_sectionOne_q3: 'Episode 5: The Empire Strikes Back',
            EQ_sectionOne_q4: 'BB8',
            EQ_sectionOne_q5: 'BB8',
            next: 'Save and continue'
         }
    submit name: 'Section 2', url: '${location}',
         fill_in: {
            EQ_sectionTwo_q1: '10',
            next: 'Save and continue'
         }
     submit name: 'Section 3', url: '${location}',
         fill_in: {
            EQ_sectionThree_q1: 'Bring back the Ewoks',
            next: 'Save and continue'
         }
  end
end.flood(flood_api, {
    name: 'DigitalEQ',
    privacy_flag: 'public',
    grid: '6L1xrxAzaYPvxsR1sr-X',
    region: 'ap-southeast-2'
    }
)


