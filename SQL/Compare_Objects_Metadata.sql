-- Script compares objects changed dates and outputs objects that differs
SELECT
    CASE 
		WHEN (ISNULL(DEV.[Type], LIVE.[Type])= 1)  THEN 'Table'
		WHEN (ISNULL(DEV.[Type], LIVE.[Type]) = 3) THEN 'Report'
		WHEN (ISNULL(DEV.[Type], LIVE.[Type]) = 5) THEN 'Codeunit'	
		WHEN (ISNULL(DEV.[Type], LIVE.[Type]) = 6) THEN 'XmlPort'	
		WHEN (ISNULL(DEV.[Type], LIVE.[Type]) = 7) THEN 'Menusuite'
		WHEN (ISNULL(DEV.[Type], LIVE.[Type]) = 8) THEN 'Page'
		WHEN (ISNULL(DEV.[Type], LIVE.[Type]) = 9) THEN 'Query'
		ELSE CAST(ISNULL(DEV.[Type], LIVE.[Type]) AS	nvarchar)
	END AS ObjType
	, ISNULL(DEV.[ID], LIVE.[ID]) AS ID
	, ISNULL(DEV.[Name], LIVE.[Name]) AS NAME
	, DEV.[Modified] AS DevMod
	, DEV.[BLOB Size] AS DevSize
	, format(DEV.[Date], 'd', 'et-ee') AS DevDate
	, format(DEV.[Time], 't', 'et-ee') AS DetTime
    -- format() is in SQL since 2012 ver. for older just use:
    -- ,DEV.[Date]  AS DevDate
	-- ,DEV.[Time] AS DetTime
	, DEV.[Version List] AS DevVersion
	, CASE 
		WHEN ((DEV.[Date] > LIVE.[Date]) OR (LIVE.[Date] IS NULL)) THEN '>'
		WHEN ((DEV.[Date] < LIVE.[Date]) OR (DEV.[Date]  IS NULL)) THEN '<'
		WHEN (DEV.Time > LIVE.Time) THEN '>'
		WHEN (DEV.Time < LIVE.Time) THEN '<'
		ELSE ''
	  END AS Latest
	, LIVE.[Modified] AS LiveMod
	, LIVE.[BLOB Size] AS LiveBlob
	, format(LIVE.[Date], 'd', 'et-ee') AS LiveDate
	, format(LIVE.[Time], 't', 'et-ee') AS Livetime
    -- ,LIVE.[Date] AS LiveDate
	-- ,LIVE.[Time] AS Livetime
	, LIVE.[Version List] AS Liveversion

FROM [Demo Database NAV (10-0)].[dbo].[Object] AS DEV -- Change to your DEV SQL
    FULL JOIN [Demo Database NAV (9-0)].[dbo].[Object] AS LIVE -- Change to your LIVE SQL
    ON LIVE.[Type] = DEV.[Type] AND LIVE.ID = DEV.ID

WHERE 
	(DEV.[Type] > 0 OR LIVE.[Type] > 0)
    AND
    (LIVE.[Date] <> DEV.[Date] OR LIVE.[Date] IS NULL OR DEV.[Date] IS NULL
    OR LIVE.[Time] <> DEV.[Time]
    --OR DEV.[BLOB Size] <> LIVE.[BLOB Size] 
    OR LIVE.[Version List] COLLATE DATABASE_DEFAULT <> DEV.[Version List] COLLATE DATABASE_DEFAULT
    OR LIVE.[Modified] <> DEV.[Modified])
        
