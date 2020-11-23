###############################################################################
#
# File:     storage.py
#
# Purpose:  The relational data sets structured as classes for ease of use.
#
# Copyright 2020 Mater Misericordiae Ltd.
#
###############################################################################
"""
This holds the following classes:

    * Task - the main task information
    * Post - the comments availalbe within the tasks (one-to-many)
    * Assignment - the assignees of a task (one-to-many)
    * Attachment - the attachments in a task (one-to-many)
    * Checklist - the check list, if available, of a task (one-to-many)

These classes define the properties to be setup, as well as the database insert queries, through a `save` method.
"""

# Python libraries

from bs4 import BeautifulSoup as bs
import pandas as pd
import pyodbc

def clearHtml(html):
    soup = bs(html)

    # kill all script and style elements
    for script in soup(["script", "style"]):
        script.extract()  # rip it out

    # remove garbage from Planner : <table id="x_jSanity_hideInPlanner">
    t = soup.find('table', {'id': 'x_jSanity_hideInPlanner'})
    if t:
        t.extract()

    # remove auto-generated comments from Planner : <font size="2">
    s = soup.find('font', {"size": "2"})
    if s:
        s.extract()

    # get text
    text = soup.get_text()

    # break into lines and remove leading and trailing space on each
    lines = (line.strip() for line in text.splitlines())
    # break multi-headlines into a line each
    chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
    # drop blank lines
    text = '\n'.join(chunk for chunk in chunks if chunk)

    # replace double quotation marks with single quotation marks to kick on the SET QUOTED_IDENTIFIER OFF in a query
    if '\"' in text:
        text = text.replace('\"', '\'')

    # escape issues with updating SQL table with None or empty values
    if text == '':
        text = 'None'

    return text

def exec_procedure_to_df(cs, query, meetingDate, planId, maxDays, meeting_notes_columns, meeting_notes_index_col):
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
    # make connection pyodbc
    conn = pyodbc.connect(cs)

    cursor = conn.cursor()
    conn.autocommit = True
    cursor.execute(query)

    results = cursor.fetchall()
    df = pd.DataFrame.from_records(results, columns=cols)
    conn.close()
    return df
