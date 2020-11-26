import pandas as pd
import io
import smtplib
from smtplib import SMTPAuthenticationError
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from database import exec_procedure_to_df

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

from parameters import meetingDate, planId, maxDays, meeting_notes_columns, meeting_notes_index_col, send_from, send_to, subject, body

def replace_breaks(df):
    '''
    Replace breaks '<br/>' with a new line character '\n' in a dataframe
    '''
    df = df.replace('<br/>', '\n', regex=True)
    return df


def export_excel(df):
    with io.BytesIO() as buffer:
        writer = pd.ExcelWriter(buffer)
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
        server = smtplib.SMTP('smtp.mater.org.au', '587')
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

    query_sp = 'exec [MDA-DB-DEV-CLA-AE].planner.createMeetingNotes2 ?, ?, ?'

    # exec proc
    df = exec_procedure_to_df(cs=cs, query=query_sp, meetingDate=meetingDate, planId=planId, maxDays=maxDays,
                              meeting_notes_columns=meeting_notes_columns,
                              meeting_notes_index_col=meeting_notes_index_col)

    # Clean the line breaks

    # send the dataframe
    send_dataframe(username=my_outlook_username, password=my_outlook_password, send_from=send_from, send_to=send_to,
                   subject=subject, body=body, df=df)


if __name__ == "__main__":
    run()
