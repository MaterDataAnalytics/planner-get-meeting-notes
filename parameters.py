
# user input
meetingDate = '2020-11-6'
planId = '-6-Vic94GE-s5oiwg57nAsgAFOm6'
maxDays = 30

# Clean BodyContent from TaskPost table
params = (meetingDate, planId, maxDays)
taskPostColumnNames=['PlanId', 'TaskId', 'PostId', 'CreatedDateTime', 'LoadDate', 'BodyContent', 'CleanBodyContent']

# make meeting notes
query_sp = 'exec [MDA-DB-DEV-CLA-AE].planner.createMeetingNotes2 ?, ?, ?'
meeting_notes_columns = ['Section', 'Card Created DateTime', 'Bucket', 'Card Title', 'Card Labels', 'Date Description', 'Task Description', 'Comments', 'Assigneess']
meeting_notes_index_col = 'Section'

# send email
smtp_server = 'smtp.mater.org.au'
smtp_port = '587'