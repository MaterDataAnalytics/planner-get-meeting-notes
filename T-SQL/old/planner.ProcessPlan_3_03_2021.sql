/*
###############################################################################
#
# File:     planner.ProcessPlan.sql
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
               [planner].[ProcessPlan]
 Description:   
               Populate the [planner].[Plan] table with a new data from [planner].[RawPlanDate] table. Only the records with the 'desc%' name pattern are processed.
 Parameters:    
               no parameters
 Usage:
               exec [planner].[ProcessPlan];
 Outputs:       
               processed data written into relevant table
*/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [planner].[ProcessPlan]

AS

BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    	UPDATE planner.RawPlanData
		set LoadDate = convert(datetime2, (replace(left(right(Filename, 24), 10), '_', '-') + ' ' + replace(right(left(right(Filename, 24), 19), 8), '_', ':')), 120)
			where LoadDate is NULL 
				and (Filename like 'desc%' or Filename like 'catg%')
				and ProcessedYN = 0

		insert into [planner].[Plan]
		select  A.PlanId
		,A.Title
		,A.CreatedDateTime
		,A.[Owner]
		,A.CeatedByUserDisplayName
		,A.CeatedByUserId
		,A.CeatedByApplicationDisplayName
		,A.CeatedByApplicationId
		,B.Category1
		,B.Category2
		,B.Category3
		,B.Category4
		,B.Category5
		,B.Category6
		,A.LoadDate
		,A.InsertDate
		from (
		select P.PlanId
		,JSON_VALUE(P.Content,'$.title') Title
		,convert(datetime2, JSON_VALUE(P.Content,'$.createdDateTime'), 127) CreatedDateTime
		,JSON_VALUE(P.Content,'$.owner') [Owner]
		,JSON_VALUE(P.Content,'$.createdBy.user.displayName') CeatedByUserDisplayName
		,JSON_VALUE(P.Content,'$.createdBy.user.id') CeatedByUserId
		,JSON_VALUE(P.Content,'$.createdBy.application.displayName') CeatedByApplicationDisplayName
		,JSON_VALUE(P.Content,'$.createdBy.application.id') CeatedByApplicationId
		,convert(datetime2, (replace(left(right(P.Filename, 24), 10), '_', '-') + ' ' + replace(right(left(right(P.Filename, 24), 19), 8), '_', ':')), 120) LoadDate
		,GETDATE() InsertDate
		from planner.RawPlanData P
		where 
		[Filename] like 'desc%'
		and ProcessedYN = 0
		) A
		left outer join (
			select C.PlanId
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category1') Category1
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category2') Category2
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category3') Category3
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category4') Category4
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category5') Category5
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category6') Category6
				,convert(datetime2, (replace(left(right(C.Filename, 24), 10), '_', '-') + ' ' + replace(right(left(right(C.Filename, 24), 19), 8), '_', ':')), 120) LoadDate
				from planner.RawPlanData C
				where C.[Filename] like 'catg%'
				and C.ProcessedYN = 0
				) B
		on A.PlanId = B.PlanId
		and A.LoadDate = B.LoadDate
	
	-- update the ProcessedYN in the table
		UPDATE planner.RawPlanData 
			set ProcessedYN = 1
			where Filename like 'desc%'
			or Filename like 'catg%'
		
END

GO


