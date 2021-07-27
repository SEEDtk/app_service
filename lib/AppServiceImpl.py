#BEGIN_HEADER
#END_HEADER


class AppService:
    '''
    Module Name:
    AppService

    Module Description:
    
    '''

    ######## WARNING FOR GEVENT USERS #######
    # Since asynchronous IO can lead to methods - even the same method -
    # interrupting each other, you must be *very* careful when using global
    # state. A method could easily clobber the state set by another while
    # the latter method is running.
    #########################################
    #BEGIN_CLASS_HEADER
    #END_CLASS_HEADER

    # config contains contents of config file in a hash or None if it couldn't
    # be found
    def __init__(self, config):
        #BEGIN_CONSTRUCTOR
        #END_CONSTRUCTOR
        pass

    def service_status(self, ctx):
        # ctx is the context object
        # return variables are: returnVal
        #BEGIN service_status
        #END service_status

        # At some point might do deeper type checking...
        if not isinstance(returnVal, list):
            raise ValueError('Method service_status return value ' +
                             'returnVal is not type list as required.')
        # return the results
        return [returnVal]

    def enumerate_apps(self, ctx):
        # ctx is the context object
        # return variables are: returnVal
        #BEGIN enumerate_apps
        #END enumerate_apps

        # At some point might do deeper type checking...
        if not isinstance(returnVal, list):
            raise ValueError('Method enumerate_apps return value ' +
                             'returnVal is not type list as required.')
        # return the results
        return [returnVal]

    def start_app(self, ctx, app_id, params, workspace):
        # ctx is the context object
        # return variables are: task
        #BEGIN start_app
        #END start_app

        # At some point might do deeper type checking...
        if not isinstance(task, dict):
            raise ValueError('Method start_app return value ' +
                             'task is not type dict as required.')
        # return the results
        return [task]

    def start_app2(self, ctx, app_id, params, start_params):
        # ctx is the context object
        # return variables are: task
        #BEGIN start_app2
        #END start_app2

        # At some point might do deeper type checking...
        if not isinstance(task, dict):
            raise ValueError('Method start_app2 return value ' +
                             'task is not type dict as required.')
        # return the results
        return [task]

    def query_tasks(self, ctx, task_ids):
        # ctx is the context object
        # return variables are: tasks
        #BEGIN query_tasks
        #END query_tasks

        # At some point might do deeper type checking...
        if not isinstance(tasks, dict):
            raise ValueError('Method query_tasks return value ' +
                             'tasks is not type dict as required.')
        # return the results
        return [tasks]

    def query_task_summary(self, ctx):
        # ctx is the context object
        # return variables are: status
        #BEGIN query_task_summary
        #END query_task_summary

        # At some point might do deeper type checking...
        if not isinstance(status, dict):
            raise ValueError('Method query_task_summary return value ' +
                             'status is not type dict as required.')
        # return the results
        return [status]

    def query_task_details(self, ctx, task_id):
        # ctx is the context object
        # return variables are: details
        #BEGIN query_task_details
        #END query_task_details

        # At some point might do deeper type checking...
        if not isinstance(details, dict):
            raise ValueError('Method query_task_details return value ' +
                             'details is not type dict as required.')
        # return the results
        return [details]

    def enumerate_tasks(self, ctx, offset, count):
        # ctx is the context object
        # return variables are: returnVal
        #BEGIN enumerate_tasks
        #END enumerate_tasks

        # At some point might do deeper type checking...
        if not isinstance(returnVal, list):
            raise ValueError('Method enumerate_tasks return value ' +
                             'returnVal is not type list as required.')
        # return the results
        return [returnVal]

    def kill_task(self, ctx, id):
        # ctx is the context object
        # return variables are: killed, msg
        #BEGIN kill_task
        #END kill_task

        # At some point might do deeper type checking...
        if not isinstance(killed, int):
            raise ValueError('Method kill_task return value ' +
                             'killed is not type int as required.')
        if not isinstance(msg, basestring):
            raise ValueError('Method kill_task return value ' +
                             'msg is not type basestring as required.')
        # return the results
        return [killed, msg]

    def rerun_task(self, ctx, id):
        # ctx is the context object
        # return variables are: new_task
        #BEGIN rerun_task
        #END rerun_task

        # At some point might do deeper type checking...
        if not isinstance(new_task, basestring):
            raise ValueError('Method rerun_task return value ' +
                             'new_task is not type basestring as required.')
        # return the results
        return [new_task]
