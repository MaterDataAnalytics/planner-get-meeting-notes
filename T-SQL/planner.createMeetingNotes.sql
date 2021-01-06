/****** Object:  StoredProcedure [planner].[createMeetingNotes]    Script Date: 06/01/2021 2:31:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Description: <Create a final view for meeting notes using CleanBodyContent for Comments>
-- =============================================
CREATE PROCEDURE [planner].[createMeetingNotes]
(
		@meetingDate  datetime
		,@planId  varchar(1000) 
		,@maxDays  int
)		
AS

BEGIN

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
			isnull(s1.[Index], 99) as [__SortBucket],
			isnull(s2.[Index], 99) as [__SortTask],
			t.CreatedDateTime as [Card Created DateTime],
			b.BucketName as Bucket,
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

			select 1 as [Index],   'sds4wgPMLU6dgGF_P0lEucgAIsU2' as BucketId -- ?? Agenda
			union all
			select 2 as [Index],   'RbM_UCr3Q0ahe66zicnSuMgALvIV' as BucketId -- ??? Better outcomes
			union all
			select 2 as [Index],   'Plp2Vj5sxk6ImAgF6wzNh8gAD0YC' as BucketId -- ???? Improved experience ????????????
			union all
			select 2 as [Index],   'X1SG91SzS0C08wOw38WxBMgAPw2a' as BucketId -- ?? Lower Cost
			union all
			select 2 as [Index],   'duOah9ppSEmPCA0KBIQm_cgAAFzY' as BucketId -- ?? Quadruple Aim Initiatives
			union all
			select 3 as [Index],   'm8qnSzgjnUmMLZHCIwsl-MgAGn13' as BucketId -- ?? Actions
			union all
			select 4 as [Index],   'fXFrFvXA1UqxMmv1ZXTq-sgAJ7s-' as BucketId -- ?? Messages
		) s1
		on s1.BucketId = b.BucketId

		left join (

			-- create a sorting index for the meeting template based on the task (important stuff first)

			select 1 as [Index],   'M_5gZ-hkZkqIDTnUKnQcicgAGT2I' as TaskId -- ? Meeting Focus and Attendees
			union all
			select 2 as [Index],   'UdVwLNHcLEWsmSN8UYzMGMgAD7QB' as TaskId -- Acknowledgement of Country
			union all
			select 3 as [Index],   'IFZA5ulDDUevRZGX1Z1fesgADYZf' as TaskId -- ?? Matters to report up

			-- everything else no need to be sorted (index 99)

		) s2
		on s2.TaskId = t.TaskId

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


