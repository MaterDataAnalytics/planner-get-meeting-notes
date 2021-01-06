/****** Object:  StoredProcedure [o365].[ProcessUsers]    Script Date: 06/01/2021 2:29:53 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:      <Alina Motygullina, Fercen Curapiaca>
-- Create Date: <November 6, 2020>
-- Description: <Creates a table with the parsed user data. The data come from the [o365].[RawADData] >
-- =============================================
CREATE PROCEDURE [o365].[ProcessUsers]

AS

BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    	UPDATE [o365].[RawADData]
		set LoadDate = convert(datetime2, (replace(left(right([FileName], 25), 10), '_', '-') + ' ' + replace(right(left(right([FileName], 25), 19), 8), '_', ':')), 120)
			where LoadDate is NULL 
				and ProcessedYN = 0

	insert into [o365].[User]
	SELECT distinct A.UserId
		,A.DisplayName
		,A.GivenName
		,A.Surname
		,A.Email
		,A.JobTitle
		,A.OfficeLocation
		,A.MobilePhone
		,A.BusinessPhones
		,A.PreferredLanguage
		,A.UserPrincipalName
		,convert(datetime2, (replace(left(right(P.FileName, 25), 10), '_', '-') + ' ' + replace(right(left(right(P.FileName, 25), 19), 8), '_', ':')), 120) as LoadDate
		,GETDATE() InsertDate
		from [o365].[RawADData] P
			cross apply openjson(P.Content, '$.value')
				with([UserId] varchar(200) '$.id'
				,[DisplayName] varchar(200) '$.displayName'
				,[GivenName] varchar(100) '$.givenName'
				,[JobTitle] varchar(200) '$.jobTitle'
				,[Email] varchar(100) '$.mail'
				,[MobilePhone] varchar(100) '$.mobilePhone'
				,[OfficeLocation] varchar(1000) '$.officeLocation'
				,[PreferredLanguage] varchar(100) '$.preferredLanguage'
				,[Surname] varchar(500) '$.surname'
				,[UserPrincipalName] varchar(500) '$.userPrincipalName'
				,[BusinessPhones] varchar(1000) '$.businessPhones'
				,[Email] varchar(100) '$.mail') A
		where P.ProcessedYN = 0

	-- update the ProcessedYN in the table
		UPDATE [o365].[RawADData]
			set ProcessedYN = 1
			where ProcessedYN = 0
		
END

GO


