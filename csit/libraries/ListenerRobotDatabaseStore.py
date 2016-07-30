import psycopg2
import os
from robot.libraries.BuiltIn import BuiltIn


class ListenerRobotDatabaseStore:
    ROBOT_LISTENER_API_VERSION = 2
    conn = None
    cursor = None

    def __init__(self, database_name, user, password, host, port):
        self.ROBOT_LIBRARY_LISTENER = self
        self.database_name = database_name
        self.user = user
        self.password = password
        self.host = host
        self.port = port

        params = {
            'dbname': self.database_name,
            'user': self.user,
            'password': self.password,
            'host': self.host,
            'port': self.port
        }
        
        self.conn = psycopg2.connect(**params)
        self.cursor = self.conn.cursor()

    def insert_into_table(self, status, startTime, elapsedTime, critical, testName, jobName, buildNumber):
        '''
            Insert the required data into robot_results table
        '''
        try:
            self.cursor.execute("INSERT INTO scripts_Robot_Results(job_name,status,elapsed_time,start_time,critical,test_name,build_number)" +
                                "VALUES" + "(%s,%s,%s,%s,%s,%s,%s)", (jobName, status, elapsedTime, startTime, critical, testName, buildNumber))
            self.conn.commit()
        except self.conn.DatabaseError, error:
            print 'Error %s' % error

    def end_test(self, name, attrs):
        '''
            Retrieving data required and then storing it in the database
        '''
        status = attrs['status']
        startTime = attrs['starttime']
        elapsedTime = attrs['elapsedtime']
        critical = attrs['critical']
        testName = name
        jobName = BuiltIn().get_variables()['${project_name}']
        buildNumber = os.environ['BUILD_NUMBER']
        try:
            self.insert_into_table(
                status, startTime, elapsedTime, critical, testName, jobName, buildNumber)
        except self.conn.DatabaseError, error:
            if self.conn:
                self.conn.rollback()
            print 'Error %s' % error
        finally:
            if self.conn:
                self.conn.close()
