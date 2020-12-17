'''



'''

import pandas as pd
import io
import pickle
import smtplib
from smtplib import SMTPAuthenticationError
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import logging
from datetime import datetime

from database import exec_procedure_to_df, query_to_df

from config import my_outlook_username, my_outlook_password, username, password, my_username, my_password

from parameters import planId, maxDays, meeting_notes_columns, meeting_notes_index_col, send_from, send_to, \
    subject, body


def replace_breaks(df):
    r"""
    Replace breaks '<br/>' with a new line character '\n' in a dataframe

    :param df: input dataframe

    :return: output dataframe
    """

    df = df.replace('<br/>', '\n', regex=True)
    return df


def export_excel(df):
    '''
    Exel exporter to creae an Excel file as an IO buffer to avoid saving a physical copy

    :param df: input datagrame

    :return: buffer value
    '''

    with io.BytesIO() as buffer:
        writer = pd.ExcelWriter(buffer)
        df.to_excel(writer)
        writer.save()
        return buffer.getvalue()


def send_dataframe(username, password, send_from, send_to, subject, body, df):
    '''
    Send data via email as an Excel attachment

    :param username: SMTP server username (usually mater email address @mater.org.au)

    :param password: SMTP server password (usually mater email password)

    :param send_from: mater email address

    :param send_to: mater email address

    :param subject: email subject

    :param body: email body text

    :param df: dataframe to send as an Excel attachment

    :return: error message in case of error
    '''

    # logger
    logger = logging.getLogger('main_logger')

    multipart = MIMEMultipart()
    multipart['From'] = send_from
    multipart['To'] = send_to
    multipart['Subject'] = subject

    EXPORTERS = {'meeting_notes.xlsx': export_excel}

    for filename in EXPORTERS:
        attachment = MIMEApplication(EXPORTERS[filename](df))
        attachment['Content-Disposition'] = 'attachment; filename="{}"'.format(filename)
        multipart.attach(attachment)
    multipart.attach(MIMEText(body, 'html'))
    try:
        server = smtplib.SMTP('smtp.mater.org.au', '587')
    except smtplib.socket.gaierror:
        logger.error('smtplib.socket.gaierror')
        return False
    server.ehlo()
    server.starttls()
    server.ehlo()
    try:
        server.login(username, password)
    except SMTPAuthenticationError:
        logger.error('SMTPAuthenticationError')
        server.quit()
        print('Authentication FAILED. Incorrect login credentials. Check username and password.')
        return False

    server.sendmail(send_from, send_to, multipart.as_string())
    logger.info('Email with meeting notes sent successfully')
    server.quit()


def run(cs, query_sp, meetingDate):
    '''
    Run the pipeline of sending the meeting notes

    :param cs: connecting string, specified in ping_func()
    :param query_sp: query string to execute a stored procedure, specified in ping_func()
    :param meetingDate: meeting date identified as a date of 'Meeting Agenda and Attendees' task completion

    :return:
    '''

    # exec proc
    df = exec_procedure_to_df(cs=cs, query=query_sp, meetingDate=meetingDate, planId=planId, maxDays=maxDays,
                              meeting_notes_columns=meeting_notes_columns,
                              meeting_notes_index_col=meeting_notes_index_col)
    logger.info('Procedure executed and dataframe created')

    # send the dataframe
    send_dataframe(username=my_outlook_username, password=my_outlook_password, send_from=send_from, send_to=send_to,
                   subject=subject, body=body, df=replace_breaks(df))
    logger.info('Email sent successfully')


def ping_func():
    '''
    The polling function, to kick-start run.py when the condition met: a new 'Meeting Agenda and Attendees' task was marked as 'completed'

    :return:
    '''

    # add logger
    logger = logging.getLogger('main_logger')

    # (1) == Get the 'Meeting agenda and Attendees' Task latest record <-- this will be only one row with the latest CompletedDateTime
    query = '''
    select top(1) PlanId
    ,BucketId
    ,TaskId
    ,Title
    ,PercentComplete
    ,CreatedDateTime
    ,CompletedDateTime
    ,LoadDate
    from [planner].[Task]
    where LoadDate= (select max(LoadDate) from [planner].[TaskPost])
    and BucketId = 'sds4wgPMLU6dgGF_P0lEucgAIsU2'
    and title like '%meeting focus and attendees%'
    and CompletedDateTime is not NULL
    order by CompletedDateTime desc
    '''

    query_sp_prod = 'exec [MDA-DB-DW-CLA-AE].planner.createMeetingNotes ?, ?, ?'
    query_sp_dev = 'exec [MDA-DB-DEV-CLA-AE].planner.createMeetingNotes ?, ?, ?'

    cs_prod = (
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=mda-sql-dw-cla-ae.database.windows.net;"
        "DATABASE=MDA-DB-DW-CLA-AE;"
        f"UID={username};"
        f"PWD={password};"
    )

    cs_dev = (
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "Authentication=ActiveDirectoryPassword;"
        "SERVER=mda-sql-aap-dev-ase.database.windows.net;"
        "DATABASE=MDA-DB-DEV-CLA-AE;"
        f"UID={my_username};"
        f"PWD={my_password};"
    )

    task_df = query_to_df(cs=cs_prod, query=query,
                          cols=['PlanId', 'BucketId', 'TaskId', 'Title', 'PercentComplete', 'CreatedDateTime',
                                'CompletedDateTime', 'LoadDate'])

    # (2) == compare CompletedDateTime with the previous meeting date ====

    # (2.1) == unpickle previous meeting date
    try:
        previous_meeting_date = pickle.load(open('previous_meeting_date.pickle', 'rb'))
    except (OSError, IOError) as e:
        logger.info('Creating previous meeting date, because no value was found')
        previous_meeting_date = task_df.loc[0, "CompletedDateTime"]
        pickle.dump(previous_meeting_date, open('previous_meeting_date.pickle', 'wb'))

    if previous_meeting_date < task_df.loc[0, 'CompletedDateTime']:
        # (2.2) == extract meeting notes and send the email with Excel file attached
        meetingDate = task_df.loc[0, 'CompletedDateTime']
        run(cs=cs_prod, query_sp=query_sp_prod, meetingDate=meetingDate)

        # (2.3) == update a previous_meeting_date and export variable somehow
        previous_meeting_date = task_df.loc[0, 'CompletedDateTime']

        # (2.4) == save the updated previous_meeting_date
        pickle.dump(previous_meeting_date, open('previous_meeting_date.pickle', 'wb'))
        logger.info(f'New meeting has been holden on {previous_meeting_date}')

    else:
        logger.info('New meeting has not been holden yet')
        logger.info(f'Last meeting has been holden on {previous_meeting_date}')


if __name__ == "__main__":
    # Add logger
    logger = logging.getLogger('main_logger')
    logger.setLevel(logging.INFO)
    # create a file handler
    fh = logging.FileHandler('planner_get_meeting_notes.log', mode='a', encoding=None, delay=False)
    fh.setLevel(logging.DEBUG)

    # format
    formatter = logging.Formatter('-->%(asctime)s - %(name)s:%(levelname)s - %(message)s')
    fh.setFormatter(formatter)

    # add the handlers to the logger
    logger.addHandler(fh)

    ping_func()
