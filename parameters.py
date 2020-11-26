# user input
meetingDate = '2020-11-4'
planId = '-6-Vic94GE-s5oiwg57nAsgAFOm6'
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
send_to = 'alina.motygullina@mater.org.au'
subject = f'Meeting notes {meetingDate}'
body = 'Please find the file attached'
