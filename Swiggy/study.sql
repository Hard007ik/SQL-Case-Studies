use campusx;

select * from swiggy;

select
sum(case when hotel_name='' then 1 else 0 end) as hotelWithName,
sum(case when rating='' then 1 else 0 end) as ratingsNull,
sum(case when time_minutes='' then 1 else 0 end) as timeEmpty,
sum(case when food_type='' then 1 else 0 end) as foodTypeNull,
sum(case when location='' then 1 else 0 end) as locationNull,
sum(case when offer_above='' then 1 else 0 end) as offerEmpty,
sum(case when offer_percentage='' then 1 else 0 end) as offerPCTNull
from swiggy;

-- schema, group concat, concat, prepare, execute

select *
from information_schema.columns where table_name='swiggy';

-- get column names
select COLUMN_NAME
from information_schema.columns
where table_name='swiggy';

-- concat
select concat("Gujarat ","India"); 

-- group concat: concates o/p of concat function

select 
group_concat(
	concat(
    'sum(case when `', column_name, '`='''' then 1 else 0 end) as `', column_name, '`'
    )
) into @sql
from information_schema.columns where table_name='swiggy';

select @sql;

set @sql = concat('select ', @sql, ' from swiggy');
select @sql;

-- prepare variable that stores query in string
prepare smt from @sql;
-- execute the prepared variable 
execute smt;
-- remove all alocated storeg with executed variable
deallocate prepare smt;

-- all thing as stored procedure
drop procedure count_empty_row;

DELIMITER //
CREATE PROCEDURE count_empty_row()
BEGIN
	SELECT GROUP_CONCAT(
		CONCAT(
		'sum(case when `', column_name, '`='''' then 1 else 0 end) as `', column_name, '`'
        )
    ) INTO @sql
    FROM information_schema.columns WHERE table_name='swiggy';
    
    SET @sql = CONCAT('select ', @sql, ' from swiggy');
    
    PREPARE smt FROM @sql;
    
    EXECUTE smt;
    
    DEALLOCATE PREPARE smt;
    
END;
//
DELIMITER ; 


call count_empty_row();

-- shifting values of rating to time_minutes

DELIMITER //
CREATE FUNCTION first_part( col varchar(100))
RETURNS varchar(100)
DETERMINISTIC
BEGIN
	SET @l = LOCATE(' ', col);
    SET @s = IF (@l>0, LEFT(col, @l-1), col);
    RETURN @s;
END;
// 
DELIMITER ;

with clean as (
select * from swiggy where rating like '%mins%'
),

cleaned as (
select *, first_part(rating) as 'rat' from clean
)

update swiggy s
inner join cleaned c 
on c.hotel_name=s.hotel_name
set s.time_minutes=c.rat;




-- clean '-' from time_minutes col
DELIMITER //
CREATE FUNCTION first_part2( col varchar(100))
RETURNS varchar(100)
DETERMINISTIC
BEGIN
	SET @l = LOCATE('-', col);
    SET @s = IF (@l>0, LEFT(col, @l-1), col);
    RETURN @s;
END;
// 
DELIMITER ;


DELIMITER //
CREATE FUNCTION last_part( col varchar(100))
RETURNS varchar(100)
DETERMINISTIC
BEGIN
	SET @l = LOCATE('-', col);
    SET @s = IF ( @l=0, ' ', SUBSTRING(col, @l+1, LENGTH(col)) );
	RETURN @s;
END;
//
DELIMITER ;

with clean as (
select * from swiggy where time_minutes like '%-%'
),
cleaned as (
select *, first_part2(time_minutes) as firstPart, last_part(time_minutes) as lastPart from clean
)

update swiggy s
inner join cleaned c
on c.hotel_name=s.hotel_name
set s.time_minutes=round((c.firstPart+ c.lastPart)/2, 2);

-- time_minutes col is cleaned.............................



-- lets clean rating col

with t as (
select location, round(avg(rating), 1) as avg_rate
from swiggy
where rating not like '%mins%'
group by location
)

update swiggy s inner join t
on t.location=s.location
set s.rating=t.avg_rate
where s.rating like '%mins%';

-- still some rating has time values, it means that the hotel name comes only once.
set @avgRate = (select round(avg(rating), 1) from swiggy where rating not like '%mins%');
select @avgRate;

update swiggy
set rating=@avgRate
where rating like '%mins%';

select * from swiggy where rating like '%mins%';

-- rating col is cleaned...

-- Now lets clean location

select distinct location from swiggy where location like '%Kandivali%'; -- 258

select distinct location from swiggy where location like '%east%'; -- 554
select distinct location from swiggy where location like '%west%';

select distinct count(location) from swiggy where location like '%Kandivali%east%'; -- 154

update swiggy
set location='Kandivali East'
where location like '%Kandivali%east%';

-- just like for west
update swiggy
set location='Kandivali West'
where location like '%Kandivali%west%';

update swiggy
set location='Kandivali East'
where location like '%Kandivali%(E)%';

update swiggy
set location='Kandivali West'
where location like '%Kandivali%W%';

-- location col is done

-- Now cleaning offer_percentage col.

update swiggy
set offer_percentage=0
where offer_above='not_available';

-- percentage column is also cleaned.



-- Now its time for cleaning food_type column

select max(length(food_type)) from swiggy; -- '167'
select food_type from swiggy where length(food_type)=167;
-- 'Bakery, Beverages, Maharashtrian, Snacks, Street Food, South Indian, Punjabi, Chaat, Indian, American, North Indian, Fast Food, Desserts, Cafe, Healthy Food, Home Food'

select substring_index('Bakery, Beverages, Maharashtrian, Snacks, Street Food, 
South Indian, Punjabi, Chaat, Indian, American, North Indian, 
Fast Food, Desserts, Cafe, Healthy Food, Home Food',',',3);

select substring_index('Bakery, Beverages, Maharashtrian, Snacks, Street Food, 
South Indian, Punjabi, Chaat, Indian, American, North Indian, 
Fast Food, Desserts, Cafe, Healthy Food, Home Food',',',-3);


select substring_index(substring_index('Bakery, Beverages, Maharashtrian, Snacks, Street Food, 
South Indian, Punjabi, Chaat, Indian, American, North Indian, 
Fast Food, Desserts, Cafe, Healthy Food, Home Food',',',3), ',', -1) as t;


select char_length('Bakery, Beverages, Maharashtrian, Snacks, Street Food, 
South Indian, Punjabi, Chaat, Indian, American, North Indian, 
Fast Food, Desserts, Cafe, Healthy Food, Home Food'); -- 169


select char_length(replace('Bakery, Beverages, Maharashtrian, Snacks, Street Food, 
South Indian, Punjabi, Chaat, Indian, American, North Indian, 
Fast Food, Desserts, Cafe, Healthy Food, Home Food', ',', '')) as t; -- 154



select substring_index(substring_index(food_type,',',v.n), ',', -1) as food
from swiggy s
inner join
(
	select 1+a.N + b.N*10 as n from
	(
	SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
				UNION ALL SELECT 8 UNION ALL SELECT 9
	) as a
	cross join
	(
	SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
				UNION ALL SELECT 8 UNION ALL SELECT 9
	) as b
) as v
on char_length(s.food_type)-char_length(replace(s.food_type, ',', '')) >= v.n-1;





