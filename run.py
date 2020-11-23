import pyodbc
import pandas as pd
import io
import smtplib
from smtplib import SMTPAuthenticationError
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from database import query_to_df, exec_procedure_to_df
from database import clearHtml

from config import cs
# cs should be of the following format:
#
# cs = (
#     "DRIVER={ODBC Driver 17 for SQL Server};"
#     "Authentication=ActiveDirectoryPassword;"
#     "SERVER=mda-sql-aap-dev-ase.database.windows.net;"
#     "DATABASE=MDA-DB-DEV-CLA-AE;"
#     "UID=YOUR_USERNAME_TO_SQL_DB;"
#     "PWD=YOUR_PASSWORD_SQL_DB;"
#     )
from config import my_outlook_username, my_outlook_password

from parameters import query_sp, meetingDate, planId, maxDays,meeting_notes_columns, meeting_notes_index_col

def clean_body_content(cs, query_tp, cols):

    # get the dataframe
    df = query_to_df(cs, query_tp, cols=cols)

    # clean BodyContent
    df['CleanBodyContent'] = df['BodyContent'].apply(lambda x: clearHtml(x))

    # create a pyodbc connection
    conn = pyodbc.connect(cs)

    cursor = conn.cursor()
    conn.autocommit = True

    # loop throgh the rows to update value
    for i, row in df.iterrows():
        query_insert_tp = """
        update [planner].[TaskPost]
        set CleanBodyContent = ?
        where PlanId = ?
          and TaskId = ?
          and PostId = ?
          and CreatedDateTime = ?
          and LoadDate = ?
          and CleanBodyContent is NULL
        """
        cursor.execute(query_insert_tp, (
            row[cols[6]]
            , row[cols[0]]
            , row[cols[1]]
            , row[cols[2]]
            , row[cols[3]]
            , row[cols[4]]
        )
                       )
    conn.close()

def replace_breaks(df):
    '''
    Replace breaks '<br/>' with a new line character '\n' in a dataframe
    '''
    df = df.replace('<br/>', '\n', regex=True)
    return df

def export_excel(df):
    with io.BytesIO() as buffer:
        writer=pd.ExcelWriter(buffer)
        df.to_excel(writer)
        writer.save()
        return buffer.getvalue()

def send_dataframe(username, password, send_from, send_to, subject, body, df):
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
        server = smtplib.SMTP('smtp.mater.org.au','587')
    except smtplib.socket.gaierror:
        return False
    server.ehlo()
    server.starttls()
    server.ehlo()
    try:
        server.login(username, password)
    except SMTPAuthenticationError:
        server.quit()
        print('Authentication FAILED. Incorrect login credentials. Check username and password.')
        return False

    server.sendmail(send_from, send_to, multipart.as_string())
    print('Email sent successfully')
    server.quit()

def run():
    # exec proc
    df = exec_procedure_to_df(cs=cs, query=query_sp, meetingDate=meetingDate, planId=planId, maxDays=maxDays,
                              meeting_notes_columns=meeting_notes_columns,
                              meeting_notes_index_col=meeting_notes_index_col)

    # Clean the line breaks
    df = df.replace('<br/>', '\n', regex=True)

    # send the dataframe
    send_dataframe(username=my_outlook_username, password=my_outlook_password, send_from='alina.motygullina2@mater.org.au', send_to='alina.motygullina2@mater.org.au',
                   subject='TEST: sending meeting notes with Python',
                   body='This is test. \nPlease find the file attached', df=df)


if __name__ =="__main__":
    run()
