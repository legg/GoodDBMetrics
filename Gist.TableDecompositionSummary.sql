/*
	Good DB Metrics - Decomposition Summary Tool (relevant to T-SQL and SQL Server)
	---------------
	Motivation: A tool to summaries the decomposable data structures in a database
	Author: Max Legg
	Description: Finds the decomposable data structures within a table that use null across a whole database.
	The dynamic queries check the data to see which columns actually use null for each table. 
	Each row represents a unique data structure that can be used to help analyse the decomposable parts.
	Read the free paper How To Handle Missing Information Without Using NULL by Hugh Darwen.
*/

declare @tables table(Id int, TABLE_SCHEMA nvarchar(128), TABLE_NAME nvarchar(128), Decomposition int)
insert into @tables
select ROW_NUMBER() over (order by TABLE_SCHEMA + TABLE_NAME) as Id, TABLE_SCHEMA, TABLE_NAME, 0
from information_schema.COLUMNS c
where c.IS_NULLABLE = 'YES'
group by TABLE_SCHEMA, TABLE_NAME

declare @index int = 1
declare @total int = (select COUNT(*) from @tables)
declare @table_schema nvarchar(128), @table_name nvarchar(128)
declare @sql nvarchar(max)
declare @count int
declare @counttable table (Id int, [count] int)

while @index <= @total
begin
	select @table_schema = TABLE_SCHEMA, @table_name = TABLE_NAME from @tables where Id = @index
	
	select @sql = 'select '+convert(nvarchar,@index)+', count(*) from ( select ' + STUFF((
		select ',case when ['+c.COLUMN_NAME+'] is not null then convert(bit,1) else convert(bit,0) end as ['+c.COLUMN_NAME+']'
		from information_schema.COLUMNS c
		join @tables t on c.TABLE_SCHEMA = t.TABLE_SCHEMA and c.TABLE_NAME = t.TABLE_NAME
		where t.Id = @index
		for xml path('')),1,1,'') + 
		' from ' + @table_schema + '.' + @table_name + ' group by ' + STUFF((
		select ',case when ['+c.COLUMN_NAME+'] is not null then convert(bit,1) else convert(bit,0) end'
		from information_schema.COLUMNS c
		join @tables t on c.TABLE_SCHEMA = t.TABLE_SCHEMA and c.TABLE_NAME = t.TABLE_NAME
		where t.Id = @index
		for xml path('')),1,1,'') + ')x'
	
	insert into @counttable
	exec sp_executesql @sql
	
	set @index = @index + 1
end


update t
set Decomposition = c.[count]
from @tables t
join @counttable c on t.Id = c.Id

select *
from @tables
order by Decomposition desc