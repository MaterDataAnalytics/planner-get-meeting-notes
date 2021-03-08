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
               [planner].[ProcessPlanCategories]
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

CREATE PROCEDURE [planner].[ProcessPlanCategories]

AS

BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    	UPDATE planner.RawPlanData
		set LoadDate = convert(datetime2, (replace(left(right(Filename, 24), 10), '_', '-') + ' ' + replace(right(left(right(Filename, 24), 19), 8), '_', ':')), 120)
			where LoadDate is NULL 
				and Filename like 'catg%'
				and ProcessedYN = 0

		insert into [planner].[PlanCategories]
		select C.PlanId
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category1') Category1
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category2') Category2
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category3') Category3
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category4') Category4
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category5') Category5
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category6') Category6
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category7') Category7
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category8') Category8
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category9') Category9
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category10') Category10
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category11') Category11
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category12') Category12
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category13') Category13
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category14') Category14
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category15') Category15
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category16') Category16
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category17') Category17
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category18') Category18
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category19') Category19
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category20') Category20
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category21') Category21
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category22') Category22
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category23') Category23
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category24') Category24
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category25') Category25
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category26') Category26
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category27') Category27
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category28') Category28
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category29') Category29
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category30') Category30
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category31') Category31
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category32') Category32
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category33') Category33
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category34') Category34
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category35') Category35
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category36') Category36
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category37') Category37
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category38') Category38
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category39') Category39
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category40') Category40
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category41') Category41
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category42') Category42
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category43') Category43
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category44') Category44
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category45') Category45
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category46') Category46
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category47') Category47
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category48') Category48
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category49') Category49
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category50') Category50
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category51') Category51
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category52') Category52
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category53') Category53
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category54') Category54
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category55') Category55
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category56') Category56
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category57') Category57
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category58') Category58
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category59') Category59
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category60') Category60
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category61') Category61
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category62') Category62
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category63') Category63
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category64') Category64
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category65') Category65
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category66') Category66
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category67') Category67
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category68') Category68
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category69') Category69
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category70') Category70
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category71') Category71
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category72') Category72
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category73') Category73
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category74') Category74
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category75') Category75
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category76') Category76
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category77') Category77
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category78') Category78
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category79') Category79
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category80') Category80
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category81') Category81
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category82') Category82
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category83') Category83
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category84') Category84
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category85') Category85
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category86') Category86
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category87') Category87
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category88') Category88
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category89') Category89
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category90') Category90
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category91') Category91
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category92') Category92
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category93') Category93
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category94') Category94
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category95') Category95
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category96') Category96
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category97') Category97
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category98') Category98
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category99') Category99
				,JSON_VALUE(C.Content,'$.categoryDescriptions.category100') Category100
				,convert(datetime2, (replace(left(right(C.Filename, 24), 10), '_', '-') + ' ' + replace(right(left(right(C.Filename, 24), 19), 8), '_', ':')), 120) LoadDate
				,GETDATE() InsertDate
				from planner.RawPlanData C
				where C.[Filename] like 'catg%'
				and C.ProcessedYN = 0
	
	-- update the ProcessedYN in the table
		UPDATE planner.RawPlanData 
			set ProcessedYN = 1
			where Filename like 'catg%'
		
END

GO


