require 'rubygems'
require 'ruby-jmeter'

HOST = 'preprod-surveys.eq.ons.digital'
PROTOCOL = 'https'
PORT = '443'
CONNECT_TIMEOUT_MS = '10000'
RESPONSE_TIMEOUT_MS = '10000'
USERS = 300
REPEAT = 1
RAMP_UP = 5
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
    random_variable maximumValue: 10000000,
        minimumValue: 1,
        perThread: false,
        variableName: 'ru_ref'
end

def get_healthcheck()
    visit name: 'status', url: '/status' do
        assert contains: 'OK', scope: 'main'
    end
end

def extract_url()
    extract regex: '(.*)', name: 'url', useHeaders: 'URL'
end

def start_survey()
    jwt_params = {
        user_id: 'ruby-jmeter',
        schema: '0_star_wars.json',
        exp: '1800',
        period_str: 'May 2016',
        period_id: '201605',
        collection_exercise_sid: '000',
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
    submit name: 'post dev form', url: '/dev', fill_in: jwt_params do
        assert contains: ['Star Wars', jwt_params[:ru_name]], scope: 'main'
        extract_url
    end
end

def post_introduction()
    submit name: 'continue introduction', url: '${url}',
            fill_in: { "action[start_questionnaire]":'' } do
        assert contains: ['Star Wars Quiz', 'When was The Empire Strikes Back released'], scope: 'main'
        extract_url
    end
end

def post_page_1_empty()
    submit name: 'post page 1 (empty)', url: '${url}',
            fill_in: {
                "6cf5c72a-c1bf-4d0c-af6c-d0f07bc5b65b":"",
                "92e49d93-cbdc-4bcb-adb2-0e0af6c9a07c":"",
                "a5dc09e8-36f2-4bf4-97be-c9e6ca8cbe0d":"",
                "9587eb9b-f24e-4dc0-ac94-66117b896c10[]":"",
                "6fd644b0-798e-4a58-a393-a438b32fe637-day":"",
                "6fd644b0-798e-4a58-a393-a438b32fe637-month":"",
                "6fd644b0-798e-4a58-a393-a438b32fe637-year":"",
                "06a6a4b7-6ce4-4687-879d-3443cd8e2ff0-day":"",
                "06a6a4b7-6ce4-4687-879d-3443cd8e2ff0-month":"",
                "06a6a4b7-6ce4-4687-879d-3443cd8e2ff0-year":"",
                "action[save_continue]": "" } do
        assert contains: ['This field is mandatory.', 'date entered is not valid'], scope: 'main'
        extract_url
    end
end

def post_page_1_filled()
    submit name: 'post page 1 (filled)', url: '${url}',
            fill_in: {
                "6cf5c72a-c1bf-4d0c-af6c-d0f07bc5b65b":"99",
                "92e49d93-cbdc-4bcb-adb2-0e0af6c9a07c":"1024",
                "a5dc09e8-36f2-4bf4-97be-c9e6ca8cbe0d":"Lion",
                "9587eb9b-f24e-4dc0-ac94-66117b896c10[]":"Yoda",
                "6fd644b0-798e-4a58-a393-a438b32fe637-day":"1",
                "6fd644b0-798e-4a58-a393-a438b32fe637-month":"6",
                "6fd644b0-798e-4a58-a393-a438b32fe637-year":"2015",
                "06a6a4b7-6ce4-4687-879d-3443cd8e2ff0-day":"1",
                "06a6a4b7-6ce4-4687-879d-3443cd8e2ff0-month":"5",
                "06a6a4b7-6ce4-4687-879d-3443cd8e2ff0-year":"2016",
                "action[save_continue]": ""
            } do
        assert contains: ['Ewokes', 'medal'], scope: 'main'
        extract_url
    end
end

def post_page_2_filled()
    submit name: 'post page 2 (filled)', url: '${url}',
            fill_in: {
                "215015b1-f87c-4740-9fd4-f01f707ef558":"No comment",
                "7587qe9b-f24e-4dc0-ac94-66118b896c10":"No",
                "action[save_continue]": ""
            } do
        assert contains: 'Your responses', scope: 'main'
        extract_url
    end
end

def post_final_submission()
    submit name: 'post final submission', url: '${url}',
            fill_in: { "action[submit_answers]": "" } do
        assert contains: ['Thank You', 'Transaction ID'], scope: 'main'
    end
end

test do
    setup_test

    threads count: USERS, loops: REPEAT, ramp_time: RAMP_UP do

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

            post_page_2_filled

            post_final_submission
        end

        # Show the results in the UI
        view_results_tree
        summary_report
    end
end.run(
    file: 'survey_runner_jmeter.jmx',
    jtl: 'result.jtl',
    gui: true)
