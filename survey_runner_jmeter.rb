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
        maximumValue: 10000000,
        minimumValue: 1,
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
                "6fd644b0-798e-4a58-a393-a438b32fe637-day":"",
                "6fd644b0-798e-4a58-a393-a438b32fe637-month":"",
                "6fd644b0-798e-4a58-a393-a438b32fe637-year":"",
                "06a6a4b7-6ce4-4687-879d-3443cd8e2ff0-day":"",
                "06a6a4b7-6ce4-4687-879d-3443cd8e2ff0-month":"",
                "06a6a4b7-6ce4-4687-879d-3443cd8e2ff0-year":"",
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
                "6fd644b0-798e-4a58-a393-a438b32fe637-day":"1",
                "6fd644b0-798e-4a58-a393-a438b32fe637-month":"1",
                "6fd644b0-798e-4a58-a393-a438b32fe637-year":"2015",
                #  to
                "06a6a4b7-6ce4-4687-879d-3443cd8e2ff0-day":"1",
                "06a6a4b7-6ce4-4687-879d-3443cd8e2ff0-month":"1",
                "06a6a4b7-6ce4-4687-879d-3443cd8e2ff0-year":"2016",
                # total sales of food
                "bb8168e6-2272-450d-b5a7-d3170508efb2":"10000",
                # total sales of alcohol
                "fee0b9fe-4c3a-4c14-9611-4fa9e2e9578a":"15000",
                # total sales of clothing
                "01ac2ebf-d49d-45e8-8f7a-0f847aa7cf25":"20000",
                # total sales of household goods
                "7605c4a9-2c3a-483c-908b-e07244105ac4":"25000",
                # total sales of other goods
                "5843e26e-a139-4645-baa9-51bdb0aba27b":"30000",
                # total retail turnover
                "e81adc6d-6fb0-4155-969c-d0d646f15345":"120000",
                # from internet sales
                "4b75a6f7-9774-4b2b-82dc-976561189a99":"60000",
                # sales of automotive fuel
                "b2bac3ed-5504-43ef-a883-f9ca8496aca3":"0",
                # Comments
                "fef6edc2-d98c-4d4d-9a7c-997ce10c361f":"",
                "action[save_continue]": ""
            } do
    assert contains: 'Your responses', scope: 'main'
        extract_url
    end
end


def post_final_submission()
    submit name: 'POST final submission', url: '${url}',
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
