###############################################################################
#
# File:     database.py
#
# Purpose:  database operations.
#
# Copyright 2020 Mater Misericordiae Ltd.
#
###############################################################################

'''

Functions to pull data from database by running a query or executing a stored procedure.

The output is saved to a pandas dataframe for further consumption.

*Copyright 2020 Mater Misericordiae Ltd.*

'''

from bs4 import BeautifulSoup as bs
import pandas as pd
import pyodbc


def exec_procedure_to_df(cs, query, meetingDate, planId, maxDays, meeting_notes_columns, meeting_notes_index_col):
    '''
    Execute a stored procedure

    :param cs: connection string for the ODBC SQL server

    :param query: query to run, e.g ' exec planner.stored_procedure_name param1_value, param2_value'

    :param meetingDate: meeting date

    :param planId: meeting ID

    :param maxDays: how many days backwards to take into account

    :param meeting_notes_columns: column names for meeting notes export file

    :param meeting_notes_index_col: index column name

    :return: dataframe
    '''
    # make connection pyodbc
    conn = pyodbc.connect(cs)

    cursor = conn.cursor()
    conn.autocommit = True
    cursor.execute(query, meetingDate, planId, maxDays)

    results = cursor.fetchall()
    df = pd.DataFrame.from_records(results, columns=meeting_notes_columns, index=meeting_notes_index_col)
    conn.close()
    return df


def query_to_df(cs, query, cols):
    '''
    Run a query

    :param cs: connection string for the ODBC SQL server

    :param query: query to run, e.g 'select * from planner.table'

    :param cols: column names in the output dataframe

    :return: dataframe
    '''
    # make connection pyodbc
    conn = pyodbc.connect(cs)

    cursor = conn.cursor()
    conn.autocommit = True
    cursor.execute(query)

    results = cursor.fetchall()
    df = pd.DataFrame.from_records(results, columns=cols)
    conn.close()
    return df
