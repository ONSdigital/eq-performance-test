require 'rubygems'
require 'ruby-jmeter'

LAUNCHER_HOST = ENV['LAUNCHER_HOST'] || 'preprod-new-surveys-launch.eq.ons.digital'
HOST = ENV['HOST'] || 'preprod-new-surveys.eq.ons.digital'
PROTOCOL = ENV['PROTOCOL'] || 'https'
PORT = ENV['PORT'] || '443'

CONNECT_TIMEOUT_MS = '240000'
RESPONSE_TIMEOUT_MS = '240000'
USERS = ENV['USERS'] || '100'
REPEAT = ENV['REPEAT'] || '1'
RAMP_UP = 5
DURATION_SECONDS = 0
STEP_DELAY_MS = '10000'
STEP_DELAY_VARIANCE_MS = '5000'


def setup_test()
    defaults domain: HOST,
        protocol: PROTOCOL,
        port: PORT,
        connect_timeout: CONNECT_TIMEOUT_MS,
        response_timeout: RESPONSE_TIMEOUT_MS,
        image_parser: false
end

def initialise_variables()
    # Use a random number for the ru_ref
    random_variable name: 'Random ru_ref',
        maximumValue: 900000000000,
        minimumValue: 100000000000,
        perThread: false,
        variableName: 'ru_ref'

    # Use a random number for the collection exercise
    random_variable name: 'Random collection exercise',
        maximumValue: 10000000,
        minimumValue: 1,
        perThread: false,
        variableName: 'collect_exercise_sid'
end

def get_healthcheck()
    visit name: 'Get /status', url: '/status' do
        assert contains: 'OK', scope: 'main'
    end
end

def extract_url()
    extract regex: '(.*)', name: 'url', useHeaders: 'URL'
end

def extract_csrf()
    extract regex: '<input id="csrf_token" name="csrf_token" type="hidden" value="(.+?)">', name: 'csrf_token'
end

def start_survey()
    jwt_params = {
        user_id: 'ruby-jmeter',
        schema: '2_0001.json',
        exp: '1800',
        period_str: 'May 2016',
        period_id: '201605',
        collection_exercise_sid: '${collect_exercise_sid}',
        ru_ref: '${ru_ref}',
        ru_name: 'JMeter',
        ref_p_start_date: '2016-05-01',
        ref_p_end_date: '2016-05-31',
        return_by: '2016-06-12',
        trad_as: 'Ruby JMeter',
        employment_date: '2016-06-10',
        action_launch: 'Open Survey'
    }

    # Go to the /dev page and start the questionnaire
    submit name: 'POST launcher', url: LAUNCHER_HOST, fill_in: jwt_params do
        assert contains: ['Quarterly Business Survey', jwt_params[:ru_name]], scope: 'main'
        extract_url
        extract_csrf
    end
end

def post_introduction()
    header [
        { name: 'referer', value: '${url}' }
    ]

    submit name: 'POST introduction', url: '${url}',
            fill_in: {
              "action[start_questionnaire]":"",
              "csrf_token" => "${csrf_token}" } do
        assert contains: ['On 1 May 2016, what was the number of employees for Ruby JMeter'], scope: 'main'
        extract_url
        extract_csrf
    end
end

def post_number_of_employees()
    submit name: 'POST number of employees', url: '${url}',
            fill_in: {
                "number-of-employees-total": "4",
                "action[save_continue]": "",
                "csrf_token" => "${csrf_token}" } do
        assert contains: ['Of the 4 total employees employed on 1 May 2016, how many male and female employees worked the following hours?'], scope: 'main'
        extract_url
        extract_csrf
    end
end

def post_employees_breakdown_invalid()
    submit name: 'POST employees breakdown (invalid)', url: '${url}',
            fill_in: {
                "number-of-employees-male-more-30-hours": "2",
                "number-of-employees-female-more-30-hours": "2",
                "number-of-employees-male-less-30-hours": "2",
                "number-of-employees-female-less-30-hours": "2",
                "action[save_continue]": "",
                "csrf_token" => "${csrf_token}"
            } do
        assert contains: ['These must be corrected to continue.'], scope: 'main'
        extract_url
        extract_csrf
    end
end

def post_employees_breakdown_valid()
    submit name: 'POST employees breakdown (valid)', url: '${url}',
            fill_in: {
                "number-of-employees-male-more-30-hours": "1",
                "number-of-employees-female-more-30-hours": "1",
                "number-of-employees-male-less-30-hours": "1",
                "number-of-employees-female-less-30-hours": "1",
                "action[save_continue]": "",
                "csrf_token" => "${csrf_token}"
            } do
        assert contains: 'Please check your answers carefully before submitting.', scope: 'main'
        extract_url
        extract_csrf
    end
end


def post_final_submission()

    submit name: 'POST final submission', url: '${url}',
            fill_in: { "action[submit_answers]": "",
            "csrf_token" => "${csrf_token}" } do
        assert contains: ['Submission Successful', 'Transaction ID'], scope: 'main'
    end
end

test do
    setup_test

    USE_SCHEDULER = DURATION_SECONDS > 0 ? true : false
    threads count: USERS.to_i,
            loops: REPEAT,
            ramp_time: RAMP_UP,
            duration: DURATION_SECONDS,
            scheduler: USE_SCHEDULER do

        initialise_variables

        get_healthcheck

        # Wait a few seconds before continuing
        think_time 2000

        # Launch the survey, fill in and submit it
        transaction name: 'Complete Survey' do
            cookies clear_each_iteration: true

            # Wait between steps a random time
            random_timer STEP_DELAY_MS, STEP_DELAY_VARIANCE_MS

            start_survey

            post_introduction

            post_number_of_employees

            post_employees_breakdown_invalid

            post_employees_breakdown_valid

            post_final_submission
        end

        view_results_tree

        summary_report update_at_xpath: [
            { "//fieldNames" => 'true' },
            { "//saveAssertionResultsFailureMessage" => 'true' },
            { "//message" => 'true' },
            { "//stringProp[@name='filename']" => 'results/summaryReport.csv' }
        ]

        aggregate_report update_at_xpath: [
            { "//fieldNames" => 'true' },
            { "//saveAssertionResultsFailureMessage" => 'true' },
            { "//message" => 'true' },
            { "//stringProp[@name='filename']" => 'results/aggregateReport.csv' }
        ]
    end
end.run(
    debug: true,
    file: 'results/survey_runner_jmeter.jmx',
    jtl: 'results/result.jtl')
