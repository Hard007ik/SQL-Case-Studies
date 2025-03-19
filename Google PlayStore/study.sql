use campusx;

-- select count(*) from `googleplaystore(impure)`;

-- select count(*) from playstore;

-- truncate table playstore;

-- Infile to load data

-- LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/playstore.csv"
-- INTO TABLE playstore
-- FIELDS TERMINATED BY ","
-- OPTIONALLY ENCLOSED BY '"'
-- LINES TERMINATED BY '\r\n'
-- IGNORE 1 ROWS; 


-- Changing column names
ALTER TABLE playstore
CHANGE COLUMN `Content Rating` `Content_Rating` varchar(255); 

ALTER TABLE playstore
CHANGE COLUMN `Last Updated` `Last_Updated` date;

ALTER TABLE playstore
CHANGE COLUMN `Current Ver` `Current_Ver` varchar(255);

ALTER TABLE playstore
CHANGE COLUMN `Android Ver` `Android_Ver` varchar(255);





/*1.You're working as a market analyst for a mobile app development company. 
Your task is to identify the most promising categories(TOP 5) for 
launching new free apps based on their average ratings.*/

select category, round(avg(rating), 2) as avg_rate
from playstore
where type='Free'
group by category
order by avg_rate desc
limit 5;

/* 2. As a business strategist for a mobile app company, 
your objective is to pinpoint the three categories that generate the most revenue from paid apps.
This calculation is based on the product of the app price and its number of installations.*/

select category, round(sum(installs*price), 2) as revenue
from playstore
where type='Paid'
group by category
order by revenue desc
limit 3;

/*3. As a data analyst for a gaming company, you're tasked with calculating the 
percentage of apps within each category. 
This information will help the company understand the distribution of gaming apps 
across different categories.*/

select distinct category from playstore order by category;

select *, (cnt/(select count(*) from playstore)) * 100 as pct from (
select category, count(app) as cnt
from playstore
group by category) as t;

/*4. As a data analyst at a mobile app-focused market research firm, 
you'll recommend whether the company should develop paid or free apps 
for each category based on the  ratings of that category.*/

with t as (
select category, type, avg(rating) as avg_rate, rank() over(partition by category order by avg(rating) desc) as dummy_rank
from playstore
group by category, type
)

select category, type, round(avg_rate, 2)
from t
where dummy_rank=1
order by category;

-- OR

with t1 as (
select category, type, avg(rating) as free_rate
from playstore
where type='Free'
group by category
),
t2 as (
select category, type, avg(rating) as paid_rate
from playstore
where type='Paid'
group by category
)

select *, if( free_rate>paid_rate, 'Develop Free App', 'Develop Paid App') as 'Development' from
(
select a.category, free_rate, paid_rate from
t1 as a inner join t2 as b on a.category=b.category
) as t;

/*5.Suppose you're a database administrator, your databases have been hacked  and hackers 
are changing price of certain apps on the database , its taking long for IT team to 
neutralize the hack , however you as a responsible manager  dont want your data to be changed , 
do some measure where the changes in price can be recorded as you cant 
stop hackers from making changes*/

-- delete trigger
drop trigger price_change_update;

-- creating table to store trigger log
create table PriceChangeLog(
app varchar(255),
old_price decimal(10, 2),
new_price decimal(10, 2),
operation_type varchar(10),
operation_date timestamp
);

select *
from PriceChangeLog;

-- temp table to check trigger functionality
create table play as select * from playstore;

-- trigger for update
DELIMITER //
create trigger price_change_update
after update on play
for each row
begin
	insert into PriceChangeLog( app, old_price, new_price, operation_type, operation_date)
    values ( NEW.app, OLD.price, NEW.price, 'update', current_timestamp());    
end;

//
DELIMITER ;


select *
from play;

update play 
set price=100
where app='Coloring book moana';

update play 
set price=100
where app='Sketch - Draw & Paint';

update play set price = 200
where category='ART_AND_DESIGN';

select *
from PriceChangeLog;

/*6. your IT team have neutralize the threat,  however hacker have made some changes in the prices, 
but becasue of your measure you have noted the changes , now you want
correct data to be inserted into the database.*/

-- first droping trigger for play table
drop trigger price_change_update;

select *, rank() over(partition by app order by operation_date) as dummy_rank
from PriceChangeLog
order by app, dummy_rank;

update play as p1
inner join (select *, rank() over(partition by app order by operation_date) as dummy_rank
from PriceChangeLog
order by app, dummy_rank) as p2  on p1.app=p2.app
set p1.price=p2.old_price
where dummy_rank=1;

select * from play where category='ART_AND_DESIGN';

/*7. As a data person you are assigned the task to investigate the correlation between two 
numeric factors: app ratings and the quantity of reviews.*/

-- correlation forumal: sum((x-xMean)*(y-yMean)) / ( sqrt( sum((x-xMean)^2)) * sqrt(sum((y-yMean)^2) ) )
-- x=rating, y=reviews

set @x = (select avg(rating) from playstore);
set @y = (select avg(reviews) from playstore);

set @nume = (
select sum( (rating-@x) * (reviews-@y) )
from playstore);

set @deno = (
select sqrt( sum((rating-@x) * (rating-@x))) * sqrt(sum((reviews-@y) * (reviews-@y)) )
from playstore);

select @x, @y, @nume, @deno;

select round(@nume/@deno, 2) as 'correlation_between_rating_reviews';

-- OR

SET @x = (SELECT ROUND(AVG(rating), 2) FROM playstore);
SET @y = (SELECT ROUND(AVG(reviews), 2) FROM playstore);    

with t as 
(
	select  *, round((rat*rat),2) as 'sqrt_x' , round((rev*rev),2) as 'sqrt_y' from
	(
		select  rating , @x, round((rating- @x),2) as 'rat' , reviews , @y, round((reviews-@y),2) as 'rev'from playstore
	)a                                                                                                                        
)
-- select * from  t
select  @numerator := round(sum(rat*rev),2) , @deno_1 := round(sum(sqrt_x),2) , @deno_2:= round(sum(sqrt_y),2) from t ; -- setp 4 
select round((@numerator)/(sqrt(@deno_1*@deno_2)),2) as corr_coeff;

/*8. Your boss noticed  that some rows in genres columns have multiple generes in them, 
which was creating issue when developing the  recommendor system from the data
he/she asssigned you the task to clean the genres column and make two genres out of it, 
rows that have only one genre will have other column as blank.*/

DELIMITER //
CREATE FUNCTION f_name(a varchar(100))
RETURNS varchar(100)
DETERMINISTIC
BEGIN
	SET @l = LOCATE(';', a);
    SET @s = IF (@l > 0, LEFT(a, @l-1), a);
    RETURN @s;
END;
//
DELIMITER ;

DELIMITER //
CREATE FUNCTION l_name(a varchar(100))
RETURNS varchar(100)
DETERMINISTIC
BEGIN
	SET @l = LOCATE(';', a);
    SET @s = if (@l=0, ' ', SUBSTRING(a, @l+1, LENGTH(a) ) );
    RETURN @s;
END;
//
DELIMITER ;

select app, genres, f_name(genres) as 'genre 1', l_name(genres) as 'genre 2' from playstore;

/*9. Your senior manager wants to know which apps are  not performing as par in their particular category, 
however he is not interested in handling too many files or
list for every  category and he/she assigned  you with a task of creating a dynamic tool where he/she  
can input a category of apps he/she  interested in and 
your tool then provides real-time feedback by
displaying apps within that category that have ratings lower than the average rating for that specific category.*/

drop procedure check_categoryApp;

DELIMITER //
CREATE PROCEDURE check_categoryApp(IN ctgr varchar(255))
BEGIN
	
    set @avgrate = (SELECT AVG(rating) as avg_rate
    FROM playstore
    WHERE category=ctgr);
    
    SELECT * FROM playstore WHERE category=ctgr AND rating<@avgrate;

END;
//
DELIMITER ;

CALL check_categoryApp('business');



-- 10. what is duration time and fetch time.


-- Duration Time :- Duration time is how long  it takes system to completely understand the instructions given  from start to end  in proper order  and way.
-- Fetch Time :- Once the instructions are completed , fetch ttime is like the time it takes for  the system to hand back the results, it depend on how quickly  ths system
                -- can find  and bring back what you asked for.
                
-- if query is simple  and have  to show large valume of data, fetch time will be large, If query is complex duration time will be large.


/*EXAMPLE
Duration Time: Imagine you type in your search query, such as "fiction books," and hit enter. The duration time is the period it takes for the system to process your 
request from the moment you hit enter until it comprehensively understands what you're asking for and how to execute it. This includes parsing your query, 
analyzing keywords, and preparing to fetch the relevant data.

Fetch Time: Once the system has fully understood your request, it begins fetching the results. Fetch time refers to the time it takes for the system to 
retrieve and present the search results back to you.

For instance, if your query is straightforward but requires fetching a large volume of data (like all fiction books in the library), the fetch time may be
 prolonged as the system sifts through extensive records to compile the results. Conversely, if your query is complex, involving multiple criteria or parameters,
 the duration time might be longer as the system processes the intricacies of your request before initiating the fetch process.*/




select * from playstore;






































