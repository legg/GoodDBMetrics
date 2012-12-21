/*
	Good DB Metrics (relevant to T-SQL and SQL Server)
	---------------
	Motivation: I have inherited many bad database designs as a developer and found many bugs as a result of bad database design.
	The motivation for this gist is to share the idea of database maintainability through the 3VL school of thought.
	3VL is measured here by the usage of null valued columns.
	Author: Max Legg
	Description: These queries will produce metrics you can run and compare over time to see how maintainable your db is.
*/

-- Maintainability of a database represented by the amount of nulls in use
select 
	  y.Optional as [Optional Columns]
	, x.Required as [Required Columns]
	, convert(float, x.Required) / (y.Optional + x.Required) as [Maintainability %]
from 
(
	select COUNT(*) as Required
	from information_schema.COLUMNS
	where IS_NULLABLE = 'NO'
)x
join 
(
	select COUNT(*) as Optional
	from information_schema.COLUMNS
	where IS_NULLABLE = 'YES'
)y on 1=1

-- Sproc bodge scale (may miss some bodges out due to the routine_definition column size of 128 chars)
-- Due to the use of 'null' in columns extra logic is required
select 
	  Bodge
	, Total
	, CONVERT(float, bodge) / (bodge + Total) as [Compromises %]
from 
(
	select COUNT(*) as Bodge
	from information_schema.ROUTINES
	where 
	   ROUTINE_DEFINITION like '%isnull%' 
	or ROUTINE_DEFINITION like '%is null%' 
	or ROUTINE_DEFINITION like '%is not null%'
)x
join
(
	select COUNT(*) as Total
	from information_schema.ROUTINES
)y on 1=1

-- Bad relationships
select x.BadRelationships, y.Total, CONVERT(float, x.BadRelationships) / y.Total as [Bad Relationships %]
from
(
	select COUNT(*) as BadRelationships
	from information_schema.COLUMNS c
	join information_schema.KEY_COLUMN_USAGE k on k.TABLE_SCHEMA = c.TABLE_SCHEMA and k.TABLE_NAME = c.TABLE_NAME and k.COLUMN_NAME = c.COLUMN_NAME
	where c.IS_NULLABLE = 'YES'
)x
join
(
	select COUNT(*) as Total
	from information_schema.KEY_COLUMN_USAGE
)y on 1=1

-- Percentage of schemas with null values
select x.SchemasWithNull, y.Total, convert(float,x.SchemasWithNull) / y.Total as [Schema's With Null %]
from 
(
	select count(distinct TABLE_SCHEMA) AS SchemasWithNull
	from information_schema.COLUMNS c
	where c.IS_NULLABLE = 'YES'
)x
join 
(
	select count(distinct TABLE_SCHEMA) AS Total
	from information_schema.COLUMNS c
)y on 1=1

-- Percentage of tables with null values
select x.TablesWithNull, y.Total, convert(float,x.TablesWithNull) / y.Total as [Tables With Null %]
from 
(
	select count(distinct TABLE_SCHEMA+'.'+TABLE_NAME) AS TablesWithNull
	from information_schema.COLUMNS c
	where c.IS_NULLABLE = 'YES'
)x
join 
(
	select count(distinct TABLE_SCHEMA+'.'+TABLE_NAME) AS Total
	from information_schema.COLUMNS c
)y on 1=1

-- Top offenders 
select top 10 TABLE_SCHEMA + '.' + TABLE_NAME as [Offending Table], count(*) as [Total Offending Columns]
from information_schema.COLUMNS c
where c.IS_NULLABLE = 'YES'
group by c.TABLE_SCHEMA, c.TABLE_NAME
order by COUNT(*) desc

-- Fools logic
select 
	 x.[Foolean Values]
	,y.[Boolean Values]
	, [Foolean Values] / (0.000001 + [Foolean Values] + [Boolean Values]) as [Foolery]
from 
(
	select COUNT(*) [Foolean Values]
	from information_schema.COLUMNS c
	where c.data_type = 'bit'
	and is_nullable = 'YES'
) x
join 
(
	select COUNT(*) [Boolean Values]
	from information_schema.COLUMNS c
	where c.data_type = 'bit'
	and is_nullable = 'NO'
) y on 1=1