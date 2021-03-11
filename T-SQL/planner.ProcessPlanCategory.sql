/*
###############################################################################
#
# File:     planner.ProcessPlanCategories.sql
#
# Purpose:  (1) Process new records with the 'catg%' name pattern from [planner].[RawPlanDate] table and insert into [planner].[PlanCategories] table
#           (2) Parse the LoadDate from the Filename 'catg%'
#           (3) Update ProcessedYN flag in the [planner].[RawPlanDate] table in the end after processing
#
# Copyright 2020 Mater Misericordiae Ltd.
#
###############################################################################
*/

/*
 Procedure:     
               [planner].[ProcessPlanCategory]
 Description:   
               Populate the [planner].[PlanCategories] table with a new data from [planner].[RawPlanDate] table. Only the records with the 'catg%' name pattern are processed.
 Parameters:    
               no parameters
 Usage:
               exec [planner].[ProcessPlanCategories];
 Outputs:       
               processed data written into relevant table
*/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [planner].[ProcessPlanCategory]

AS

BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    	UPDATE planner.RawPlanData
		set LoadDate = convert(datetime2, (replace(left(right(Filename, 24), 10), '_', '-') + ' ' + replace(right(left(right(Filename, 24), 19), 8), '_', ':')), 120)
			where LoadDate is NULL 
				and Filename like 'catg%'
				and ProcessedYN = 0

		insert into [planner].[PlanCategory]
		select C.PlanId
				,A.[key] as CategoryName
				,A.[value] as CategoryTitle
				,C.LoadDate
				,GETDATE() as InsertDate
		from planner.RawPlanData C
			cross apply openjson(JSON_QUERY(C.Content,'$.categoryDescriptions')) A
		where C.[Filename] like 'catg%'
		and C.ProcessedYN = 0

-- update the ProcessedYN in the table
UPDATE planner.RawPlanData 
	set ProcessedYN = 1
	where Filename like 'catg%'
		
END
GO
