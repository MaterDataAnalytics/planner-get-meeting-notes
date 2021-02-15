/*
###############################################################################
#
# File:     planner.ProcessTask.sql
#
# Purpose:  (1) Process new records from [planner].[RawPlanDate] table and insert into separate columns of Task tables: 
#                   - [planner].[Task], 
#                   - [planner].[TaskCategories], 
#                   - [planner].[TaskAssignment], 
#                   - [planner].[TaskChecklist], 
#                   - [planner].[TaskPost], 
#                   - [planner].[TaskReferences]
#           (2) Parse the LoadDate from the Filename
#           (3) Update ProcessedYN flag in the [planner].[RawPlanDate] table
#
# Copyright 2020 Mater Misericordiae Ltd.
#
###############################################################################
*/

/*
 Procedure:     
               [planner].[ProcessTask]
 Description:   
               Process Raw Task Data from [planner].[RawPlanDate] table and insert into pre-created tables
 Parameters:    
               no parameters
 Usage:
               exec [planner].[ProcessTask];
 Outputs:       
               processed data written into relevant table
*/


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [planner].[ProcessTask]

AS

BEGIN

#-- derive LoadDate from a Filename for all new records (ProcessedYN = 0) with the filename pattern 'task%'
 UPDATE planner.RawPlanData
		set LoadDate = convert(datetime2, (replace(left(right(Filename, 24), 10), '_', '-') + ' ' + replace(right(left(right(Filename, 24), 19), 8), '_', ':')), 120)
		where LoadDate is NULL 
		and Filename like 'task%' 
		and ProcessedYN = 0
  ------------------------------------------------------------------------------------------------------------------------------------------------------
  insert into [planner].[Task]
		select P.PlanId
		,JSON_VALUE(P.Content,'$.task[0].bucketId') BucketId
		,JSON_VALUE(P.Content,'$.task[0].id') TaskId
		,JSON_VALUE(P.Content,'$.task[0].title') Title
		,JSON_VALUE(P.Content,'$.task[0].orderHint') OrderHint
		,JSON_VALUE(P.Content,'$.task[0].assigneePriority') AssigneePriority
		,JSON_VALUE(P.Content,'$.task[0].percentComplete') PercentComplete
		,convert(datetime2, JSON_VALUE(P.Content,'$.task[0].startDateTime'), 127) StartDateTime
		,convert(datetime2, JSON_VALUE(P.Content,'$.task[0].createdDateTime'), 127) CreatedDateTime
		,convert(datetime2, JSON_VALUE(P.Content,'$.task[0].dueDateTime'), 127) DueDateTime
		,convert(datetime2, JSON_VALUE(P.Content,'$.task[0].completedDateTime'), 127) CompletedDateTime
		,convert(datetime2, JSON_VALUE(P.Content,'$.task[0].completedBy'), 127) CompletedBy
		,JSON_VALUE(P.Content,'$.task[0].referenceCount') ReferenceCount
		,JSON_VALUE(P.Content,'$.task[0].checklistItemCount') ChecklistItemCount
		,JSON_VALUE(P.Content,'$.task[0].activeChecklistItemCount') ActiveChecklistItemCount
		,JSON_VALUE(P.Content,'$.task[0].conversationThreadId') ConversationThreadId
		,JSON_VALUE(P.Content,'$.task[0].createdBy.user.displayName') CreatedByUserDisplayName
		,JSON_VALUE(P.Content,'$.task[0].createdBy.user.id') CreatedByUserId
		,JSON_VALUE(P.Content,'$.details[0].description') TaskDescription
		,convert(datetime2, (replace(left(right(P.Filename, 24), 10), '_', '-') + ' ' + replace(right(left(right(P.Filename, 24), 19), 8), '_', ':')), 120) LoadDate
		,GETDATE() InsertDate
		from planner.RawPlanData P
		where 
		JSON_VALUE(P.Content,'$.task[0].id') is not null
        and P.ProcessedYN = 0
		and P.FileName like 'task%'

------------------------------------------------------------------------------------------------------------------------------------------------------------------
	insert into [planner].[TaskCategories]
		select C.PlanId
			,C.TaskId
			,C.Category
			,C.LoadDate
			,GETDATE() InsertDate
		from (
			select P.PlanId
			    ,JSON_VALUE(P.Content,'$.task[0].id') TaskId
				,B.[key] Category
				,convert(datetime2, (replace(left(right(P.Filename, 24), 10), '_', '-') + ' ' + replace(right(left(right(P.Filename, 24), 19), 8), '_', ':')), 120) LoadDate
				from planner.RawPlanData P
					cross apply openjson(JSON_QUERY(P.Content, '$.task[0].appliedCategories')) B
				where 
				JSON_VALUE(P.Content,'$.task[0].id') is not null
					and P.ProcessedYN = 0
					and P.FileName like 'task%'
				) C
------------------------------------------------------------------------------------------------------------------------------------------------------------------

		insert into [planner].[TaskAssignment]
		select P.PlanId
		,JSON_VALUE(P.Content,'$.task[0].bucketId') BucketId
		,JSON_VALUE(P.Content,'$.task[0].id') TaskId
		,A.[key] As AssignedToUserId
		,B.OrderHint
		,convert(datetime2,B.AssignedDateTime, 127) as AssignedDateTime
		,D.AssignedByUserDisplayName
		,D.AssignedByUserId
		,convert(datetime2, (replace(left(right(P.Filename, 24), 10), '_', '-') + ' ' + replace(right(left(right(P.Filename, 24), 19), 8), '_', ':')), 120) LoadDate
		,GETDATE() InsertDate
		from planner.RawPlanData P
			cross apply openjson(JSON_QUERY(P.Content,'$.task[0].assignments')) A
				cross apply openjson(A.[value])
					with([OrderHint] nvarchar(max) '$.orderHint',
					AssignedDateTime varchar(30) '$.assignedDateTime',
					AssignedBy nvarchar(max) '$.assignedBy' as JSON) B
						cross apply openjson(B.AssignedBy)
							with([User] nvarchar(max) '$.user' as JSON) C
								cross apply openjson(C.[User])
									with([AssignedByUserDisplayName] varchar(100) '$.displayName',
									[AssignedByUserId] varchar(100) '$.id') D
		where JSON_VALUE(P.Content,'$.task[0].id') is not null
		and A.[key] is not null
		and P.ProcessedYN = 0
		and P.FileName like 'task%'
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

		insert into [planner].[TaskChecklist]
		select P.PlanId
		,JSON_VALUE(P.Content,'$.task[0].bucketId') BucketId
		,JSON_VALUE(P.Content,'$.task[0].id') TaskId
		,JSON_VALUE(P.Content,'$.task[0].title') Title
		,A.[key] as ChecklistItemId
		,B.isChecked
		,B.ChecklistItemTitle
		,B.OrderHint
		,convert(datetime2, B.LastModifiedDateTime, 127) as LastModifiedDateTime
		,D.LastModifiedByUserDisplayName
		,D.LastModifiedByUserId
		,convert(datetime2, (replace(left(right(P.Filename, 24), 10), '_', '-') + ' ' + replace(right(left(right(P.Filename, 24), 19), 8), '_', ':')), 120) LoadDate
		,GETDATE() InsertDate
		from planner.RawPlanData P
		cross apply openjson(JSON_QUERY(P.Content,'$.details[0].checklist')) A
			cross apply openjson(A.[value])
				with(isChecked BIT '$.isChecked',
				ChecklistItemTitle varchar(300) '$.title',
				OrderHint varchar(100) '$.orderHint',
				LastModifiedDateTime varchar(30) '$.lastModifiedDateTime',
				LastModifiedBy nvarchar(max) '$.lastModifiedBy' as JSON) B
					cross apply openjson(B.LastModifiedBy)
						with([User] nvarchar(max) '$.user' as JSON) C
							cross apply openjson(C.[User])
								with(LastModifiedByUserDisplayName varchar(100) '$.displayName',
								LastModifiedByUserId varchar(100) '$.id') D
		where JSON_VALUE(P.Content,'$.task[0].id') is not null
		and A.[key] is not null
		and P.ProcessedYN = 0
		and P.FileName like 'task%'
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		insert into planner.TaskPost
		select P.PlanId
		,JSON_VALUE(P.Content,'$.task[0].bucketId') BucketId
		,JSON_VALUE(P.Content,'$.task[0].id') TaskId
		,B.PostId
		,convert(datetime2, B.CreatedDateTime, 127) CreatedDateTime
		,convert(datetime2, B.LastModifiedDateTime, 127) LastModifiedDateTime
		,B.ChangeKey
		,convert(datetime2, B.ReceivedDateTime, 127) ReceivedDateTime
		,B.HasAttachments
		,B.Categories
		,E.BodyContent
		,D.FromName
		,D.FromEmailAddress
		,B.Sender
		,convert(datetime2, (replace(left(right(P.Filename, 24), 10), '_', '-') + ' ' + replace(right(left(right(P.Filename, 24), 19), 8), '_', ':')), 120) LoadDate
		,GETDATE() InsertDate
		,NULL CleanBodyContent
		from planner.RawPlanData P
			cross apply openjson(JSON_QUERY(Content,'$.posts'))
				with ([value] nvarchar(max) '$.value' as JSON) A
					cross apply openjson(A.[value])
						with(PostId varchar(255) '$.id',
							 CreatedDateTime varchar(30) '$.createdDateTime',
							 LastModifiedDateTime varchar(30) '$.lastModifiedDateTime',
							 ChangeKey varchar(100) '$.changeKey',
							 ReceivedDateTime varchar(30) '$.receivedDateTime',
							 HasAttachments BIT '$.hasAttachments',
							 Categories nvarchar(max) '$.categories' as JSON,
							 Body nvarchar(max) '$.body' as JSON,
							 [From] nvarchar(max) '$.from' as JSON,
							 Sender nvarchar(max) '$.sender' as JSON) B
										cross apply openjson(B.[From])
											with(emailAddress nvarchar(max) '$.emailAddress' as JSON) C
												cross apply openjson(C.[emailAddress])
													with([FromName] varchar(100) '$.name',
														[FromEmailAddress] varchar(100) '$.address') D
												cross apply openjson(B.[Body])
													with(BodyContent nvarchar(max) '$.content') E
		where JSON_VALUE(P.Content,'$.task[0].id') is not null
		and B.PostId is not null		
		and P.ProcessedYN = 0
		and P.FileName like 'task%'
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        insert into planner.TaskReferences
        select
        JSON_VALUE(P.Content,'$.task[0].id') TaskId
        ,A.[key] as [URL]
		,HASHBYTES('SHA2_256',A.[Key]) HashedURL
        ,B.[Name]
        ,B.Type
        ,convert(datetime2, B.LastModifiedDateTime, 127) as LastModifiedDateTime
        ,D.LastModifiedByUserName
        ,D.LastModifiedByUserId
		,convert(datetime2, (replace(left(right(P.Filename, 24), 10), '_', '-') + ' ' + replace(right(left(right(P.Filename, 24), 19), 8), '_', ':')), 120) LoadDate
		,GETDATE() InsertDate
        from planner.RawPlanData P
            cross apply openjson(JSON_QUERY(P.Content,'$.details[0].references')) A
                cross apply openjson(A.[value])
                    with([Name] varchar(1000) '$.alias',
                    [Type] varchar(30) '$.type',
                    PreviewPriority varchar(200) '$.previewPriority',
                    LastModifiedDateTime varchar(30) '$.lastModifiedDateTime',
                    LastModifiedBy nvarchar(max) '$.lastModifiedBy' as JSON) B
                        cross apply openjson(B.lastModifiedBy)
                            with([User] nvarchar(max) '$.user' as JSON) C
                                cross apply openjson(C.[User])
                                    with([LastModifiedByUserName] varchar(100) '$.displayName',
                                    [LastModifiedByUserId] varchar(100) '$.id') D
		where P.ProcessedYN = 0
		and P.FileName like 'task%'
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# -- change the flag ProcessedYN for the processed records in the source planner.RawPlanData  table
	UPDATE planner.RawPlanData 
			set ProcessedYN = 1
			where [FileName] like 'task%'
END
GO


