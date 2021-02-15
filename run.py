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
from datetime import datetime

from database import exec_procedure_to_df, query_to_df

from parameters import planId_dict, maxDays, meeting_notes_columns, meeting_notes_index_col, send_from, send_to, \
    subject, body

# import CONFIG file for DEV or PROD
import configparser

config = configparser.ConfigParser()
config.read('config.ini')

CONFIG = config['PROD']

# add the path for mda-python-lib
sys.path.insert(0, CONFIG['MDA_PYTHON_LIB'])

# MDA imports
from mater.mda.utils.sql import Db
from mater.core.logger import Log, LogLevel

Log.setLogLevel(LogLevel.INFO)


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

def make_email_subject(planId):
    '''

    :param planId: plan ID of the meeting that is a key iin the planId_dict dictionary
    :return: string for the email subject
    '''
    from parameters import planId_dict
    return f'Meeting notes for the meeting {planId_dict[planId]}'

def map_planId_tite(planId):
    '''

    :param planId: plan ID
    :return: the title of the plan with the planId
    '''

    from parameters import planId_dict
    return planId_dict[planId]

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
        Log.error('smtplib.socket.gaierror was encountered')
        return False
    server.ehlo()
    server.starttls()
    server.ehlo()
    try:
        server.login(username, password)
    except SMTPAuthenticationError:
        Log.error('Authentication FAILED. Incorrect login credentials. Check username and password.')
        server.quit()
        return False

    server.sendmail(send_from, send_to, multipart.as_string())
    Log.info(f'Email with {subject} sent successfully')
    server.quit()


def run(cs, query_sp, planId, meetingDate):
    '''
    Run the pipeline of sending the meeting notes

    :param cs: connecting string, specified in ping_func()
    :param query_sp: query string to execute a stored procedure, specified in ping_func()
    :param planId: meeting planID to get the meeting notes for
    :param meetingDate: meeting date identified as a date of 'Meeting Agenda and Attendees' task completion

    :return:
    '''

    # exec proc
    df = exec_procedure_to_df(cs=cs, query=query_sp, meetingDate=meetingDate, planId=planId, maxDays=maxDays,
                              meeting_notes_columns=meeting_notes_columns,
                              meeting_notes_index_col=meeting_notes_index_col)
    Log.info(f'Procedure executed and dataframe created for plan {map_planId_tite(planId)}')

    # send the dataframe
    send_dataframe(username=CONFIG['outlook_username'], password=CONFIG['outlook_password'], send_from=send_from,
                   send_to=send_to,
                   subject=make_email_subject(planId), body=body, df=replace_breaks(df))
    Log.info(f'Email for plan {map_planId_tite(planId)} sent successfully')


def ping_func(planId_dict):
    '''
    The polling function, to kick-start run.py when the condition met: a new 'Meeting Agenda and Attendees' task was marked as 'completed'

    :return:
    '''

    # (1) == Get the 'Meeting agenda and Attendees' Task latest record <-- this will be only one row with the latest CompletedDateTime

    query = '''
        declare @dateReference as datetime = ?
        declare @planId as varchar(200) = ?
        
        select 
            t.PlanId, 
            min(t.CompletedDateTime) as CompletedDateTime
        from [planner].[Task] t
            inner join [planner].PlanBucket b 
                on t.PlanId = b.PlanId and t.LoadDate = b.LoadDate and t.BucketId = b.BucketId
            inner join [planner].[Plan] p 
                on t.PlanId = p.PlanId and t.LoadDate = p.LoadDate
        where t.LoadDate= (select max(LoadDate) from [planner].[Task])
            and b.BucketName like '%agenda%'
            and t.title like '%meeting focus and attendees%'
            and p.PlanId = @planId
            and t.CompletedDateTime is not NULL
            and t.CompletedDateTime > dateadd(day, -1, @dateReference)
        group by t.PlanId
    '''

    # set reference_date to None
    reference_date = None

    # check if the user-input arguments exist and action them
    if len(sys.argv) >= 2:
        try:
            opts, args = getopt.gnu_getopt(
                sys.argv[1:], "hd:", ["date="]
            )
        except getopt.GetoptError as err:
            Log.error(str(err) + '. See --help for more information.')

        # run query with date argument as reference date
        for option, val in opts:
            if option in ("-h", "--help"):
                usage()
                sys.exit(0)
            elif option in ("-d", "--date"):
                reference_date = val
                Log.info(f'User specified the reference date: {reference_date}')
            else:
                assert False, "Unhandled option, see --help for usage options"

    # check if the date option was provided by a user, and if not - assign 'by default' date: now()
    if reference_date is None:
        reference_date = datetime.now().strftime("%Y-%m-%d")
        Log.info(f'Reference date was NOT specified by a user and was set to a default value: {reference_date}')

    query_sp = CONFIG['query_sp']
    cs = CONFIG['cs']

    # check that there are any plans with meetings to be processes
    for planId in planId_dict:
        task_df = query_to_df(reference_date, planId, cs=cs, query=query,
                              cols=['planId', 'CompletedDateTime'])

        # create meeting notes for all new meetings
        if not task_df.empty:
            for ind, row in task_df.iterrows():
                run(cs=cs, query_sp=query_sp, planId=planId, meetingDate=task_df.loc[ind, 'CompletedDateTime'])
        else:
            Log.info(f'New meeting for {map_planId_tite(planId)} has not been held yet')


if __name__ == "__main__":

    ping_func(planId_dict=planId_dict)
