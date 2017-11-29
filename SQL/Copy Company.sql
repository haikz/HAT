-- =============================================
-- Copies NAV company to another.
-- NB: target company will be totaly owerwritten !!
-- target company must exist and accessed atleast once (nav company initialize) prior to this script
-- tables in target and source database are allowed to be different schema, but tables that exists only in target will not be owerwritten
-- =============================================
-- initialize
declare @sourcecompany varchar(max) = 'CRONUS International Ltd_'
declare @sourcedb varchar(max) ='Demo Database NAV'
declare @targetcompany varchar(max) = 'CRONUS International Ltd_'
declare @targetdb varchar(max) = 'Demo Database NAV (10-0)'
RETURN
-- COMMENT THIS OUT! Disables not deliberately runs
-- end initialize

SET NOCOUNT ON;
declare @tablename varchar(1000)
declare @targetColumns varchar(max)
declare @sourceColumns varchar(max)
declare @columnname varchar (max)
declare @existsSource tinyint
declare @targettable varchar (max)
declare @isidentity int
declare @isnumeric int
declare @tablevar table(name varchar(300))
declare @columntablevar table(COLUMN_NAME varchar(300),
    ExistsInSource tinyint)
declare @sqlcommand nvarchar (max) = 'select SUBSTRING(TObj.name,LEN('''+@targetcompany+''')+1,LEN(TObj.name)) from ['+@targetdb+'].sys.all_objects AS TObj where type=''U'' and object_id>0 and name like '''+@targetcompany+'$%'''
set @sqlcommand = @sqlcommand+' AND EXISTS(select TOP 1 1 from ['+@sourcedb+'].sys.all_objects AS SObj where SObj.type=TObj.type and SObj.name LIKE ''%''+SUBSTRING(TObj.name,LEN('''+@targetcompany+''')+1,LEN(TObj.name)))'
--set @sqlcommand = @sqlcommand+' AND name like''%$Customer'' ' -- For table specific debugging

insert into @tablevar
    (name)
exec sp_executesql  @sqlcommand
DECLARE table_cursor CURSOR for select name
from @tablevar
OPEN table_cursor
FETCH NEXT FROM table_cursor INTO @tablename
WHILE @@FETCH_STATUS = 0 BEGIN
    set @sqlcommand = 'SELECT COLUMN_NAME'
    set @sqlcommand = @sqlcommand + ' ,(SELECT TOP 1 1 FROM ['+@sourcedb+'].INFORMATION_SCHEMA.COLUMNS AS SCol WHERE SCol.TABLE_NAME = '''+@sourcecompany+@tablename+''' and SCol.COLUMN_NAME = TCol.COLUMN_NAME) AS ExistsInSource'
    set @sqlcommand = @sqlcommand + ' FROM ['+@targetdb+'].INFORMATION_SCHEMA.COLUMNS AS TCol WHERE TABLE_NAME = '''+@targetcompany+@tablename+''' and COLUMN_NAME <> ''timestamp'''

    DELETE from @columntablevar
    insert into @columntablevar
        (COLUMN_NAME, ExistsInSource)
    exec sp_executesql  @sqlcommand
    select @sourceColumns=''
    select @targetColumns=''
    -- set columns            
    DECLARE column_cursor CURSOR for select COLUMN_NAME, ExistsInSource
    from @columntablevar
    OPEN column_cursor
    FETCH NEXT from column_cursor INTO @columnname, @existsSource
    WHILE @@FETCH_STATUS=0 BEGIN
        SELECT @targetColumns = @targetColumns+',['+@columnname+']'
        IF (@existsSource = 1)
			SELECT @sourceColumns=@sourceColumns+',['+@columnname+']' 
		ELSE BEGIN
            set @sqlcommand = 'SELECT @isnumeric = COUNT(*) FROM ['+@targetdb+'].INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '''+@targetcompany+@tablename+''' AND  COLUMN_NAME = '''+@columnname+''' AND data_type IN (''tinyint'',''int'',''decimal'')'
            exec sp_executesql @sqlcommand, N'@isnumeric int output', @isnumeric output
            IF (@isnumeric>0)
				SELECT @sourceColumns=@sourceColumns+',''0''' 		
			ELSE
				SELECT @sourceColumns=@sourceColumns+','''''
            PRINT ' väli '''+@columnname+ ''' jäeti vahele, tabel: '+@tablename
        END
        FETCH NEXT from column_cursor INTO @columnname, @existsSource
    END
    CLOSE column_cursor;
    DEALLOCATE column_cursor;
    select @targetColumns = SUBSTRING(@targetColumns,2,LEN(@targetColumns)-1)
    select @sourceColumns = SUBSTRING(@sourceColumns,2,LEN(@sourceColumns)-1)

    select @targettable= '['+ @targetdb+'].dbo.['+@targetcompany+@tablename+']'
    -- if auto increment fields exists, SET IDENTITY_INSERT to ON     
    set @sqlcommand = 'SELECT @isidentity =  COUNT(*) FROM ['+@targetdb+'].sys.columns c join ['+@targetdb+'].sys.objects o on c.object_id = o.object_id where o.name = '''+@targetcompany+@tablename+''' and o.is_ms_shipped = 0 and o.type = ''U'' and c.is_identity = 1'
    exec sp_executesql @sqlcommand, N'@isidentity int output', @isidentity output

    RAISERROR (@targettable, 0, 1) WITH NOWAIT
    set @sqlcommand = ''
    IF (@isidentity>0)
        set @sqlcommand = @sqlcommand + 'SET IDENTITY_INSERT '+@targettable+' ON;'

    set @sqlcommand = @sqlcommand + 'delete from '+@targettable+';'
    set @sqlcommand = @sqlcommand + 'insert into '+@targettable+ ' ('+ @targetColumns + ')'
		+ ' select '+@sourceColumns + ' from ['+ @sourcedb+'].dbo.['+ @sourcecompany+@tablename+']'

    IF (@isidentity>0)
        set @sqlcommand = @sqlcommand + ';SET IDENTITY_INSERT '+@targettable+' OFF'
    exec sp_executesql @sqlcommand
    --print @sqlcommand
    FETCH NEXT FROM table_cursor INTO @tablename
END
CLOSE table_cursor;
DEALLOCATE table_cursor;