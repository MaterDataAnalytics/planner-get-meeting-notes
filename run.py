'''



'''

import pandas as pd
import io
import smtplib
import getopt
import sys
from smtplib import SMTPAuthenticationError
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import logging
from datetime import datetime

from database import exec_procedure_to_df, query_to_df

from parameters import planId, maxDays, meeting_notes_columns, meeting_notes_index_col, send_from, send_to, \
    subject, body

# import CONFIG file for DEV or PROD
import configparser

config = configparser.ConfigParser()
config.read('config.ini')

CONFIG = config['DEV']


def usage():
    """
    Help output.
    Print out how to use the available options.
    """

    print("""
    Usage: python -m run [reference_date]

    Runs generic script to send meeting notes if a new meeting occurred.
    Available options:

     -h, --help         Displays this help message
     -d --date          Use the value as a reference date to create meeting notes if a meeting was hold within last 24 hours.
                        Default option is now().
                        Expected format: 'YYYY-M-D'
                        Example: python -m run -d "2020-7-5"
    """)


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
    send_dataframe(username=CONFIG['outlook_username'], password=CONFIG['outlook_password'], send_from=send_from,
                   send_to=send_to,
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
        declare @dateReference as datetime = ?
        select 
            t.planid, 
            max(t.CompletedDateTime) as CompletedDateTime
        from [planner].[Task] t
            inner join [planner].PlanBucket b 
                on t.PlanId = b.PlanId and t.LoadDate = b.LoadDate and t.BucketId = b.BucketId
            inner join [planner].[Plan] p 
                on t.PlanId = p.PlanId and t.LoadDate = p.LoadDate
        where t.LoadDate= (select max(LoadDate) from [planner].[Task])
            and b.BucketName like '%agenda%'
            and t.title like '%meeting focus and attendees%'
            and p.Title like '%committee%'
            and t.CompletedDateTime is not NULL
            and t.CompletedDateTime > dateadd(day, -1, @dateReference)
        group by t.PlanId
    '''

    if len(sys.argv) < 2:
        reference_date = datetime.now().strftime("%Y-%m-%d")
    else:
        try:
            opts, args = getopt.gnu_getopt(
                sys.argv[1:], "hd:", ["date="]
            )
        except getopt.GetoptError as err:
            logging.error(str(err) + '.See --help for more information.')
            print(str(err) + '.See --help for more information.')
        # run query with date argument as reference date
        for option, val in opts:
            if option in ("-h", "--help"):
                usage()
                sys.exit(0)
            elif option in ("-d", "--date"):
                reference_date = val
            else:
                assert False, "Unhandled option, see --help for usage options"

    query_sp = CONFIG['query_sp']
    cs = CONFIG['cs']

    # check that there are any plans with meetings to be processes
    task_df = query_to_df(reference_date, cs=cs, query=query, cols=['planId', 'CompletedDateTime'])

    # create meeting notes for all new meetings
    if not task_df.empty:
        for ind, row in task_df.iterrows():
            run(cs=cs, query_sp=query_sp, meetingDate=task_df.loc[ind, 'CompletedDateTime'])
    else:
        logger.info('New meeting has not been held yet')


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
