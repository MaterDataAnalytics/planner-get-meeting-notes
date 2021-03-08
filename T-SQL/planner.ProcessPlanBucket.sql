/*
###############################################################################
#
# File:     planner.ProcessPlanBucket.sql
#
# Purpose:  (1) Process new records with the 'buck%' name pattern from [planner].[RawPlanDate] table and insert into [planner].[PlanBucket] table
#           (2) Parse the LoadDate from the Filename
#           (3) Update ProcessedYN flag in the [planner].[RawPlanDate] table in the end after processing
#
# Copyright 2020 Mater Misericordiae Ltd.
#
###############################################################################
*/

/*
 Procedure:     
               [planner].[ProcessPlanBucket]
 Description:   
               Populate the [planner].[PlanBucket] table with a new data from [planner].[RawPlanDate] table. Only the records with the 'buck%' name pattern are processed.
 Parameters:    
               no parameters
 Usage:
               exec [planner].[ProcessPlanBucket];
 Outputs:       
               processed data written into relevant table
*/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [planner].[ProcessPlanBucket]

AS

BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements.
    SET NOCOUNT ON

	DECLARE @LoadDate as datetime
	declare @PlanId as varchar(200)
	declare @Filename as varchar(200)

	-- (1) update the LoadDate field in the RawPlanData if ProcessedYN=0 and filename is 'buck_plan_%' (for new records that are plan buckets)
	UPDATE planner.RawPlanData
	set LoadDate = convert(datetime2, (replace(left(right(Filename, 24), 10), '_', '-') + ' ' + replace(right(left(right(Filename, 24), 19), 8), '_', ':')), 120)
	where LoadDate is NULL 
		and Filename like 'buck%' 
		and ProcessedYN = 0

	declare cur cursor for 
	SELECT 
		[Filename]
		,PlanId
		,LoadDate
	from planner.RawPlanData
	WHERE [Filename] like 'buck%' 
		and ProcessedYN = 0;

	-- (2) Insert parsed Plan Description data into [planner].[PlanBucket]. Table [planner].[PlanBucket] was created in accordance with a common DevOps parctice. No need to check IF EXISTS in procedures
	OPEN cur
	fetch next from cur into @Filename, @PlanId, @LoadDate

	while @@FETCH_STATUS = 0
	BEGIN
		insert into [planner].[PlanBucket]
		select P.PlanId
		,A.BucketName
		,A.OrderHint
		,A.BucketId
		,@LoadDate LoadDate
		,GETDATE() InsertDate
		from planner.RawPlanData P
			cross apply openjson(JSON_QUERY(Content,'$.value'))
				with(BucketName nvarchar(100) '$.name',
				     OrderHint varchar(100) '$.orderHint',
					 BucketId varchar(100) '$.id') A
		where PlanId = @PlanId
    		    and [FileName] = @Filename
			    and LoadDate = @LoadDate 
				and ProcessedYN = 0 
	
	-- update the ProcessedYN in the table
		UPDATE planner.RawPlanData
			set ProcessedYN = 1
			where PlanId = @PlanId
    			and [FileName] = @Filename
				and LoadDate = @LoadDate 
				and ProcessedYN = 0 

		-- get next record before continuing
		fetch next from cur into @Filename, @PlanId, @LoadDate
	END

	close cur
	deallocate cur

END
GO


