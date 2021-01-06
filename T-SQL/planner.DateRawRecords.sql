/****** Object:  StoredProcedure [planner].[DateRawRecords]    Script Date: 06/01/2021 2:32:08 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Fercen Curapiaca
-- Create Date: 07/08/2020
-- Description: <Description, , >
-- =============================================
CREATE PROCEDURE [planner].[DateRawRecords]

AS
BEGIN
	UPDATE planner.rawplan
	SET CreateDate = cast(left(left(right([FileName], 24),19),4) +'-'+ right(left(left(right([FileName], 24),19),7),2)+'-'+right(left(left(right([FileName], 24),19),10),2)+' '+right(left(left(right([FileName], 24),19),13),2)+':'+
	right(left(left(right([FileName], 24),19),16),2)+':'+right(left(left(right([FileName], 24),19),19),2) as datetime)
	,DatedYN=1
	WHERE DatedYN=0
END
GO


