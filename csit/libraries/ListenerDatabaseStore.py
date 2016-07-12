"""
ListenerDatabaseStore library for OpenDaylight project robot system test framework.
Authors: Marcus Williams - irc @ mgkwill - Intel Inc.
Updated: 2016-07-12

*Copyright (c) 2016 Intel Corp. and others.  All rights reserved.
*
* This program and the accompanying materials are made available under the
* terms of the Eclipse Public License v1.0 which accompanies this distribution,
* and is available at http://www.eclipse.org/legal/epl-v10.html

Listener that writes to PostgreSQL database when tests pass.

    Use in robot by
    loading library
    with args              '''Library           ../../../libraries/ListenerDatabaseStore.py    dbname    user
                           password   hostname   port'''

    Run Test

    At End Load dict of
    Column Schema from env
    variable               '''Load Dict Col Schema    {'TestRunId': 'VARCHAR(70) PRIMARY KEY',
                                                     'Test': 'VARCHAR(35)',
                                                     'RestPerSec': 'INT'}
                           '''

    Store Results Data     '''Store Data    {'TestRunId': '100kFlowsRest_2016-07-012-22:14:39',
                                           'Test': '100kFlowsRest', 'RestPerSec': 147998}'''
    At end of test
    the data will be
    stored in remote database once end_test() is invoked
"""

import datetime
import psycopg2


class ListenerDatabaseStore:
    ROBOT_LISTENER_API_VERSION = 2
    conn = None
    cursor = None
    test_col_schema = []
    test_row_data = []
    test_date_time = datetime.datetime.strftime(datetime.datetime.now(), '%Y-%m-%d-%H:%M:%S')

    def __init__(self, database_name, user, password, host, port):
        self.ROBOT_LIBRARY_LISTENER = self
        self.database_name = database_name
        self.user = user
        self.password = password
        self.host = host
        self.port = port

        params = {
            'dbname': self.database_name,
            'username': self.user,
            'password': self.password,
            'host': self.host,
            'port': self.port
        }

        self.conn = psycopg2.connect(**params)
        self.cursor = self.conn.cursor()

    def load_dict_col_schema(self, dict_col_schema):
        """Load a dict of column schema to use in storing data in the database.
            Args:
                :param dict_col_schema: dictionary containing column schema
                    example "{'TestRunId': 'VARCHAR(70) PRIMARY KEY',
                              'Test': 'VARCHAR(35)',
                              'RestPerSec': 'INT'}"
        """
        for column_name, column_def in dict_col_schema:
            self.test_col_schema[column_name] = column_def

    def store_data(self, test_name, data):
        """Store data in dict for later use in database.
            Args:
                :param test_name: A string that describes the test_name run
                    example 'cbench_latency'

                :param data: A string that describes the data to insert
                    example "1,'Audi',52642"

            Returns:
                :returns string: result - TRUE OR FALSE based on success creating table
            """
        test_run = test_name + "_" + self.test_date_time
        self.test_row_data[test_name] = [test_run] = test_run + ", " + data

    def check_table_exits(self, table_name, database_name):
        """Check that a table exists.
            Args:
                :param table_name: A string that describes the table to use
                    example '100kflows'

                :param database_name: A string that describes the database to use
                    example 'PERF'

            Returns:
                :returns string: result - TRUE OR FALSE based on table existence
            """
        result = 'FALSE'
        try:
            result = self.cursor.execute("""SELECT
                EXISTS(
                SELECT
                1
                FROM
                information_schema.tables
                WHERE
                table_schema = '%s'
                AND
                table_name = '%s');""" % (database_name, table_name))

        except self.conn.DatabaseError, error:
            print 'Error %s' % error
        return result

    def execute_table_cmd(self, sql_cmd, table_name, data):
        """Execute a table cmd.
            Args:
                :param table_name: A string that describes the table to use
                    example 'CBENCH'

                :param sql_cmd: A string that describes the SQL Command to use
                example 'CREATE TABLE'

                :param data: A string that describes the data to use
                    example table col attributes 'Id INTEGER PRIMARY KEY, Name VARCHAR(20), RestPerSec INT'
                    or table row data "1,'Audi',52642"

            Returns:
                :returns string: result - TRUE OR FALSE based on success creating table
            """
        result = 'FALSE'
        try:
            result = self.cursor.execute(
                "%s %s(%s)" % (sql_cmd, table_name, data))

        except self.conn.DatabaseError, error:
            print 'Error %s' % error
        return result

    def create_table(self, table_name, table_col_attributes):
        """Create a table.
            Args:
                :param table_name: A string that describes the table to use
                    example 'CBENCH'

                :param table_col_attributes: A string that describes the table columns to use
                    example 'Id INTEGER PRIMARY KEY, Name VARCHAR(20), RestPerSec INT'

            Returns:
                :returns string: result - TRUE OR FALSE based on success creating table
            """
        sql_cmd = "CREATE TABLE"

        result = self.execute_table_cmd(sql_cmd, table_name, table_col_attributes)

        return result

    def insert_into_table(self, table_name, row_data):
        """Insert data into a table.
            Args:
                :param table_name: A string that describes the table to use
                    example 'CBENCH'

                :param row_data: A string that describes the row data to insert
                    example "1,'Audi',52642"

            Returns:
                :returns string: result - TRUE OR FALSE based on success creating table
            """
        sql_cmd = "INSERT INTO"

        result = self.execute_table_cmd(sql_cmd, table_name + " VALUES", row_data)

        return result

    def end_test(self, name,  attributes):
        """Store data in PostgreSQL database using Listener Interface method
           that executes at the conclusion of a test

            Args:
                :param name: string representing name of the test

                :param attributes: dictionary with the following keys:
                    id: Test id in format like s1-s2-t2, where the beginning is
                        the parent suite id and the last part shows test index in
                        that suite. New in RF 2.8.5.
                    longname: Test name including parent suites.
                    doc: Test documentation.
                    tags: Test tags as a list of strings.
                    critical: yes or no depending is test considered critical or not.
                    template: The name of the template used for the test. An empty string
                        if the test not templated.
                    starttime: Test execution execution start time.
                    endtime: Test execution execution end time.
                    elapsedtime: Total execution time in milliseconds as an integer
                    status: Test status as string PASS or FAIL.
                    message: Status message. Normally an error message or an empty string.
        """
        if attributes['status'] == 'PASS':
            try:
                print "Storing %s Test Data" % name
                for test_name, test_run in self.test_row_data:
                    if not self.check_table_exits(test_name, self.database_name):
                        self.create_table(test_name, self.test_col_schema[test_name])
                    for test_run_sig, data in test_run:
                        self.insert_into_table(test_name, data)
                self.conn.commit()

            except self.conn.DatabaseError, error:
                if self.conn:
                    self.conn.rollback()

                print 'Error %s' % error

            finally:
                if self.conn:
                    self.conn.close()
