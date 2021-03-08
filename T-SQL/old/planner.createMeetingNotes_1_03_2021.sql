/*
###############################################################################
#
# File:     planner.createMeetingNotes.sql
#
# Purpose:  (1) Process new records with the 'desc%' name pattern from [planner].[RawPlanDate] table and insert into [planner].[Plan] table
#           (2) Parse the LoadDate from the Filename
#           (3) Update ProcessedYN flag in the [planner].[RawPlanDate] table in the end after processing
#
# Copyright 2020 Mater Misericordiae Ltd.
#
###############################################################################
*/

/*
 Procedure:     
               [planner].[createMeetingNotes]
 Description:   
               Create a final view for meeting notes using CleanBodyContent for Comments.
 Parameters:    
               @meetingDate  [datetime] - date of the meeting to use as a refernce for pulling the comments.
		       @planId  [varchar(1000)] - unique ID of the meeting plan ("Plan") that will be used to pull meeting notes from.
		       @maxDays  [int] - Number of days starting from the @meetingDate backwards to consolidate the comments left by the users under all tasks. It is used to avoid old and irrelevant comments. 
			                     For example, if @maxDays = 30 and @meetingDate ='2020-11-04', only comments that were left between 2020-10-04 ad 2020-11-04 will be pulled (within 30 days from 2020-11-04 backwards).
			   
 Usage:
               exec [planner].[createMeetingNotes];
 Outputs:       
               table with the extracted comments with the following fields:
			   [Section]
			   [Card Created DateTime]
			   [Bucket]
			   [Card Title]
			   [Card Labels]
			   [Date Description]
			   [Task Description]
			   [Comments]
			   [Assignees]
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [planner].[createMeetingNotes]
(
		@meetingDate  datetime
		,@planId  varchar(1000) 
		,@maxDays  int
)		
AS

BEGIN

	-- @separator helps to create a breaks between rows in the final Excel file.

	declare @separator varchar(5) = '<br/>'

	-- run output query -> for actions
	select
		concat([__SortBucket], '.',
			replicate('0',2 - len(rtrim([__Entry]))) + rtrim([__Entry])
		) as [Section],
		[Card Created DateTime],
		[Bucket],
		[Card Title],
		[Card Labels],
		[Date Description],
		[Task Description],
		[Comments],
		[Assigneess]
	from (
		select
			row_number() over(partition by s1.[Index] order by isnull(s1.[Index], 99), isnull(s2.[Index], 99), b.BucketName, t.CreatedDateTime asc) as [__Entry],
			/*isnull(s1.[Index], 99) as */
			s1.[Index] [__SortBucket],
			isnull(s2.[Index], 99) as [__SortTask],
			t.CreatedDateTime as [Card Created DateTime],
			b.BucketName as Bucket,
			b.bucketid,
			t.TaskId,
			t.PlanId,
			t.Title as [Card Title],
			'"' + ISNULL(c.Labels, '') + '"' as [Card Labels],
			case when t.PercentComplete = 100 then concat('completed ', convert(varchar(10), t.completedDateTime, 103))
				 when t.PercentComplete < 100 and t.dueDateTime is not null then concat('due ', convert(varchar(10), t.dueDateTime, 103))
				 else concat('created ', convert(varchar(10), t.CreatedDateTime, 103)) end as [Date Description],
			'"' + ISNULL(replace(t.TaskDescription, char(10), @separator), '') + '"' as [Task Description],
			'"' + ISNULL(replace(p.Content,char(10), @separator), '') + '"' as [Comments],
			'"' + ISNULL(a.AssignedNames, '') + '"' as [Assigneess]
		from planner.Task t

	
		inner join planner.PlanBucket b
		on t.PlanId = b.PlanId and t.BucketId = b.BucketId and t.LoadDate = b.LoadDate
		left join (
			-- get consolidated posts
			select
					ab.Planid
				,ab.BucketId
				,ab.TaskId
				,ab.LoadDate
				,string_agg(
						concat(convert(varchar(10), ab.CreatedDateTime, 103), ' by ', ab.FromName, ': ', ab.CleanBodyContent), @separator) as Content
			from (
				select Planid
					,bucketid
					,taskid
					,createddatetime
					,fromname
					,LoadDate
					,CleanBodyContent
				from planner.TaskPost
				where CreatedDateTime > DATEADD(day, -@maxDays, @meetingDate)
					and CreatedDateTime < @meetingDate
					and CleanBodyContent not like 'None'
					and CleanBodyContent is not NULL
			) ab
			group by ab.Planid, ab.bucketid, ab.taskid, ab.LoadDate

		) p
		on p.PlanId = t.PlanId and p.TaskId = t.TaskId and p.LoadDate = t.LoadDate

		left join (
			-- get consolidated caterogies
			select
				c.planid,
				c.taskid,
				c.LoadDate,
				string_agg(
					case when c.Category = 'category1' then p.Category1
							when c.Category = 'category2' then p.Category2
							when c.Category = 'category3' then p.Category3
							when c.Category = 'category4' then p.Category4
							when c.Category = 'category5' then p.Category5
							when c.Category = 'category6' then p.Category6
					else '' end
				, @separator) as Labels
			from planner.TaskCategories c
			inner join planner.[Plan] p
			on p.planId = c.PlanId and p.LoadDate = c.LoadDate
			group by c.Planid, c.taskid, c.LoadDate

		) c
		on c.PlanId = t.PlanId and c.TaskId = t.TaskId and c.LoadDate = t.LoadDate

		left join (
			-- get consolidated assignees
			select
				Planid,
				bucketid,
				taskid,
				LoadDate,
				string_agg(displayName, @separator) as AssignedNames
			from (
				select
					a.Planid,
					a.bucketid,
					a.taskid,
					a.LoadDate,
					u.displayName
				from planner.TaskAssignment a
				inner join (
					select
						y.[UserId] collate Latin1_General_BIN2 as [id],
						y.displayName collate Latin1_General_BIN2 as [displayName]
					from (
						select distinct *
						from o365.[User]
						where LoadDate = (select max(LoadDate) from o365.[User] where LoadDate < @meetingDate)
					) y
				) u
				on a.AssignedToUserId = u.id
				where a.AssignedDateTime < @meetingDate
			) a
			group by Planid, bucketid, taskid, LoadDate
		) a
		on t.PlanId = a.PlanId and t.TaskId = a.TaskId and a.LoadDate = t.LoadDate

		left join (
			-- create a sorting index for the meeting template based on the bucket (sections)
			select 
				case	when BucketName like '%Agenda%' then 1 
						when BucketName like '%outcomes%' then 2
						when BucketName like '%Improved experience%' then 2
						when BucketName like '%Lower Cost%' then 2
						when BucketName like '%Quadruple Aim Initiatives%' then 2
						when BucketName like '%Actions%' then 3
						when BucketName like '%Messages%' then 4
					else 5 end
				as [Index],
				PlanId, 
				BucketId, 
				LoadDate 
			from planner.PlanBucket
		) s1
		on s1.BucketId = b.BucketId and s1.PlanId = t.PlanId and t.LoadDate = s1.LoadDate

		left join (
			-- create a sorting index for the meeting template based on the bucket (sections)
			select 
				case	when Title like '%Meeting Focus and Attendees%' then 1 
						when Title like '%Acknowledgement of Country%' then 2
						when Title like '%Matters to report%' then 3
					else 4 end
				as [Index],
				PlanId, 
				TaskId, 
				LoadDate 
			from planner.Task
		) s2
		on s2.TaskId = t.TaskId and s2.PlanId = t.PlanId and t.LoadDate = s2.LoadDate

		where t.planid = @planId
		and t.LoadDate = (select max(LoadDate) from planner.Task where LoadDate < @meetingDate)
		and (
				(t.PercentComplete = 100 and t.completedDateTime > DATEADD(day, -@maxDays, @meetingDate))
			or
				(t.PercentComplete < 100)
		)
	) a
	order by [__SortBucket], [__Entry] asc

END
GO


