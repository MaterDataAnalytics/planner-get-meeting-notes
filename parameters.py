'''

Currently plannerget-meeting-notes library does not provide a user interface (UI).

**parameters.py** has to be modified manually if any key parameters changed. The values listed in this file are used by default.

The following parameters are managed herein:

1. Plan ID (relates to a Meeting Name) dictionary: {'planId': (plan_Title, send_to_email)}

2. Number of days counted backwards when meeting notes are being exported (old comments are not taken into account)

3. Names of columns used in the Excel output file

4. SMTP server name and port

5. Email parameters, such as **send to**, **send from**, **subject** and **email body**.

'''

# user input
planId_dict = {
    '-6-Vic94GE-s5oiwg57nAsgAFOm6': ['MMH Gov Committee', 'alina.motygullina@mater.org.au'],
    'OIJpgSEPdEmQH8qvRwC63MgADUak': ['SEQ Regional Health Exec', 'alina.motygullina@mater.org.au'],
    }
maxDays = 30

# make meeting notes
meeting_notes_columns = ['Section', 'Card Created DateTime', 'Bucket', 'Card Title', 'Card Labels', 'Date Description',
                         'Task Description', 'Comments', 'Assignees']
meeting_notes_index_col = 'Section'

# send email server
smtp_server = 'smtp.mater.org.au'
smtp_port = '587'

# email params
send_from = 'alina.motygullina@mater.org.au'
#send_to = 'alina.motygullina@mater.org.au'
#subject = 'Meeting notes for plan: '
body = 'Please find the file attached'
