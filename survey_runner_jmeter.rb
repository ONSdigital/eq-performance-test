require 'rubygems'
require 'ruby-jmeter'

HOST = ENV['HOST'] || 'preprod-surveys.eq.ons.digital'
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

def extract_url_without_block()
    extract regex: '(^(.*[\\\/]))', name: 'url', useHeaders: 'URL'
end

def start_survey()
    jwt_params = {
        user_id: 'ruby-jmeter',
        schema: '1_0205.json',
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
        submit: ''
    }

    # Go to the /dev page and start the questionnaire
    submit name: 'POST /dev form', url: '/dev', fill_in: jwt_params do
        assert contains: ['Monthly Business Survey - Retail Sales Index', jwt_params[:ru_name]], scope: 'main'
        extract_url
    end
end

def post_introduction()
    submit name: 'POST introduction', url: '${url}',
            fill_in: { "action[start_questionnaire]":'' } do
        assert contains: ['What are the dates of the sales period you are reporting for'], scope: 'main'
        extract_url
    end
end

def post_page_1_empty()
    submit name: 'POST page 1 (empty)', url: '${url}',
            fill_in: {
                "period-from-day":"",
                "period-from-month":"",
                "period-from-year":"",
                "period-to-day":"",
                "period-to-month":"",
                "period-to-year":"",
                "action[save_continue]": "" } do
        assert contains: ['These must be corrected to continue.', 'date entered is not valid'], scope: 'main'
        extract_url
    end
end

def post_page_1_filled()
    submit name: 'POST page 1 (filled)', url: '${url}',
            fill_in: {
                # sales period
                #  from
                "period-from-day":"1",
                "period-from-month":"1",
                "period-from-year":"2015",
                #  to
                "period-to-day":"1",
                "period-to-month":"1",
                "period-to-year":"2016",
                "total-sales-food":"10000",
                "total-sales-alcohol":"15000",
                "total-sales-clothing":"20000",
                "total-sales-household-goods":"25000",
                "total-sales-other-goods":"30000",
                "total-retail-turnover":"120000",
                "internet-sales":"60000",
                "total-sales-automotive-fuel":"0",
                "reason-for-change":"",
                "action[save_continue]": ""
            } do
        assert contains: 'Your responses', scope: 'main'
        extract_url_without_block
    end
end


def post_final_submission()

    submit name: 'POST final submission', url: '${url}submit-answers',
            fill_in: { "action[submit_answers]": "" } do
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

            post_page_1_empty

            post_page_1_filled

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
