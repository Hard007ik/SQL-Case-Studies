USE campusx;

-- select * from sharktank;
-- select count(*) from sharktank;

-- truncate table sharktank;

-- LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sharktank.csv'
-- INTO TABLE sharktank
-- FIELDS TERMINATED BY ','
-- OPTIONALLY ENCLOSED BY '"'
-- LINES TERMINATED BY '\r\n'
-- IGNORE 1 ROWS; 



/* 1. Your Team have to  promote shark Tank India  season 4, The senior come up with the idea to show highest 
funding domain wise  and you were assigned the task to  show the same.*/

select industry, max(Total_Deal_Amount_in_lakhs)
from sharktank
group by industry
order by industry;

-- OR

select * from 
(select industry, Total_Deal_Amount_in_lakhs, 
row_number() over(partition by industry order by Total_Deal_Amount_in_lakhs desc) as ranking
from sharktank
group by industry, Total_Deal_Amount_in_lakhs
) as t
where ranking=1;


/*2. You have been assigned the role of finding the domain where female as 
pitchers have female to male pitcher ratio >70%. */


select * , (female/male)*100 as 'fTomRatio' from (
select industry, sum(Female_Presenters) as 'female', sum(Male_Presenters) as 'male'
from sharktank 
group by industry
having sum(Female_Presenters)>0 and sum(Male_Presenters)>0
order by industry
) as t
where (female/male)>0.7;



/*3. You are working at marketing firm of Shark Tank India, you have got the task to determine 
volume of per year sale pitch made, pitches who received 
offer and pitches that were converted. Also show the percentage of 
pitches converted and percentage of pitches received.*/

select a.Season_Number, a.total, b.receive_offer, c.accept_offer,
(b.receive_offer/a.total)*100 as receive_pct, (c.accept_offer/a.total)*100 as convert_pct
from
(
select Season_Number, count(Startup_Name) as 'total'
from sharktank
group by Season_Number
) as a inner join
(
select Season_Number, count(Startup_Name) as 'receive_offer'
from sharktank
where Received_Offer='Yes'
group by Season_Number
) as b
on a.Season_Number=b.Season_Number
inner join 
(
select Season_Number, count(Startup_Name) as 'accept_offer'
from sharktank
where Accepted_Offer='Yes'
group by Season_Number
) as c
on b.Season_Number=c.Season_Number;


/*4 As a venture capital firm specializing in investing in startups featured on a renowned 
entrepreneurship TV show, how would you determine the season with the
-- highest average monthly sales and identify the top 5 industries with the 
highest average monthly sales during that season to optimize investment decisions?*/

set @s_number = ( select Season_Number from (
select Season_Number, avg(Monthly_Sales_in_lakhs) as avg_monthSale_lakhs
from sharktank
group by Season_Number
order by avg_monthSale_lakhs desc
limit 1
)as t
);

select @s_number;

select industry, round(avg(Monthly_Sales_in_lakhs), 2) as avg_monthSale_lakhs_industry
from sharktank
where Season_Number=@s_number
group by industry
order by avg_monthSale_lakhs_industry desc
limit 5;


/*5.As a data scientist at our firm, your role involves solving real-world challenges like 
identifying industries with consistent increases in funds raised over 
multiple seasons. This requires focusing on industries where data is available across all three years.
Once these industries are pinpointed, your task is to delve into the specifics, analyzing 
the number of pitches made, offers received, and offers 
converted per season within each industry.*/

-- step 1
select industry, Season_Number, sum(Total_Deal_Amount_in_lakhs) as sum_total_amt_lakhs
from sharktank
group by industry, Season_Number
order by industry, Season_Number;

-- step 2 answer
with validIndustryData as (
select industry,
sum( case when Season_Number=1 then Total_Deal_Amount_in_lakhs end) as S_1,
sum( case when Season_Number=2 then Total_Deal_Amount_in_lakhs end) as S_2,
sum( case when Season_Number=3 then Total_Deal_Amount_in_lakhs end) as S_3
from sharktank
group by industry
having S_1<S_2 and S_2<S_3 and S_1!=0
order by industry
)

-- step 3
select Season_Number, a.industry,
count(Startup_Name) as pitch_count,
count(case when Received_Offer='Yes' then a.Startup_Name end) as offer_received_count,
count(case when Accepted_Offer='Yes' then a.Startup_Name end) as offer_converted_count
from sharktank as a
inner join 
validIndustryData as b
on a.industry=b.industry
group by Season_Number, Industry;


/*6. Every shark want to  know in how much year their investment will be returned, 
so you have to create a system for them , where shark will enter the name of the 
startup's  and the based on the total deal and equity given in how many 
years their principal amount will be returned.*/

Drop procedure TOT;
DELIMITER //
CREATE PROCEDURE TOT( IN startup varchar(255))
BEGIN
	CASE
		WHEN (select Accepted_Offer from sharktank where Startup_Name=startup)='No'
			THEN select 'Offer not accepted, Turn Over TIme not calculated!';
		WHEN (select Yearly_Revenue_in_lakhs from sharktank where Startup_Name=startup)='Not Mentioned'
			THEN select 'Yearly Revenue data not available, Turn Over TIme not calculated!';
		ELSE
			select Startup_Name, Yearly_Revenue_in_lakhs, Total_Deal_Amount_in_lakhs, Total_Deal_Equity_pct,
            round(Total_Deal_Amount_in_lakhs/(Yearly_Revenue_in_lakhs*(Total_Deal_Equity_pct/100)), 2) as 'years_to_getamountback'
            from sharktank where Startup_Name=startup;
    END CASE;
END;
//
DELIMITER ;

call TOT('BluePineFoods');


/* 7. In the world of startup investing, we're curious to know which big-name investor, 
often referred to as "sharks," tends to put the most money into each
deal on average. This comparison helps us see who's the most generous with their 
investments and how they measure up against their fellow investors.*/

select sharkname, round(avg(investment), 2) as avg_investment from (
select Namita_Investment_Amount_in_lakhs as investment, 'Namita' as sharkname from sharktank 
where Namita_Investment_Amount_in_lakhs > 0
union all
select Vineeta_Investment_Amount_in_lakhs as investment, 'Vineeta' as sharkname from sharktank 
where Vineeta_Investment_Amount_in_lakhs > 0
union all
select Anupam_Investment_Amount_in_lakhs as investment, 'Anupam' as sharkname from sharktank 
where Anupam_Investment_Amount_in_lakhs > 0
union all
select Aman_Investment_Amount_in_lakhs as investment, 'Aman' as sharkname from sharktank 
where Aman_Investment_Amount_in_lakhs > 0
union all
select Peyush_Investment_Amount_in_lakhs as investment, 'Peyush' as sharkname from sharktank 
where Peyush_Investment_Amount_in_lakhs > 0
union all
select Amit_Investment_Amount_in_lakhs as investment, 'Amit' as sharkname from sharktank 
where Amit_Investment_Amount_in_lakhs > 0
union all
select Ashneer_Investment_Amount as investment, 'Ashneer' as sharkname from sharktank 
where Ashneer_Investment_Amount > 0
) as t
group by sharkname;


/*8. Develop a system that accepts inputs for the season number and the name of a shark. 
The procedure will then provide detailed insights into the total investment made by 
that specific shark across different industries during the specified season. Additionally, 
it will calculate the percentage of their investment in each sector relative to
the total investment in that year, giving a comprehensive understanding of the shark's 
investment distribution and impact.*/

DROP procedure getshark;

DELIMITER //
CREATE PROCEDURE getshark( IN season INT, IN shark VARCHAR(255) )
BEGIN
	CASE
		WHEN shark='Namita' THEN 
			SET @total = (select sum(Namita_Investment_Amount_in_lakhs) from sharktank where Season_Number=season);
            select industry, sum(Namita_Investment_Amount_in_lakhs) as investment, 
            round((sum(Namita_Investment_Amount_in_lakhs)/@total)*100, 2) as pct_investment
            from sharktank where Season_Number=season
            group by industry;
		WHEN shark='Vineeta' THEN 
			SET @total = (select sum(Vineeta_Investment_Amount_in_lakhs) from sharktank where Season_Number=season);
            select industry, sum(Vineeta_Investment_Amount_in_lakhs) as investment, 
            round((sum(Vineeta_Investment_Amount_in_lakhs)/@total)*100, 2) as pct_investment
            from sharktank where Season_Number=season
            group by industry;
		WHEN shark='Anupam' THEN 
			SET @total = (select sum(Anupam_Investment_Amount_in_lakhs) from sharktank where Season_Number=season);
            select industry, sum(Anupam_Investment_Amount_in_lakhs) as investment, 
            round((sum(Anupam_Investment_Amount_in_lakhs)/@total)*100, 2) as pct_investment
            from sharktank where Season_Number=season
            group by industry;
		WHEN shark='Aman' THEN 
			SET @total = (select sum(Aman_Investment_Amount_in_lakhs) from sharktank where Season_Number=season);
            select industry, sum(Aman_Investment_Amount_in_lakhs) as investment, 
            round((sum(Aman_Investment_Amount_in_lakhs)/@total)*100, 2) as pct_investment
            from sharktank where Season_Number=season
            group by industry;
		WHEN shark='Peyush' THEN 
			SET @total = (select sum(Peyush_Investment_Amount_in_lakhs) from sharktank where Season_Number=season);
            select industry, sum(Peyush_Investment_Amount_in_lakhs) as investment, 
            round((sum(Peyush_Investment_Amount_in_lakhs)/@total)*100, 2) as pct_investment
            from sharktank where Season_Number=season
            group by industry;
		WHEN shark='Amit' THEN 
			SET @total = (select sum(Amit_Investment_Amount_in_lakhs) from sharktank where Season_Number=season);
            select industry, sum(Amit_Investment_Amount_in_lakhs) as investment, 
            round((sum(Amit_Investment_Amount_in_lakhs)/@total)*100, 2) as pct_investment
            from sharktank where Season_Number=season
            group by industry;
		WHEN shark='Ashneer' THEN 
			SET @total = (select sum(Ashneer_Investment_Amount) from sharktank where Season_Number=season);
            select industry, sum(Ashneer_Investment_Amount) as investment, 
            round((sum(Ashneer_Investment_Amount)/@total)*100, 2) as pct_investment
            from sharktank where Season_Number=season
            group by industry;
		ELSE 
			select 'Incorrect details!';
    END CASE;
END;
//
DELIMITER ;

call getshark(2, 'Namita');


/*9. In the realm of venture capital, we're exploring which shark possesses the most 
diversified investment portfolio across various industries. 
By examining their investment patterns and preferences, we aim to uncover any discernible 
trends or strategies that may shed light on their decision-making
processes and investment philosophies.*/

select sharkname, 
count(distinct industry) as unique_industry,
count(distinct concat(Pitchers_City, ' ,', Pitchers_State)) as unique_location from (
select Industry, Pitchers_City, Pitchers_State, 'Namita' as sharkname from sharktank 
where Namita_Investment_Amount_in_lakhs > 0
union all
select Industry, Pitchers_City, Pitchers_State, 'Vineeta' as sharkname from sharktank 
where Vineeta_Investment_Amount_in_lakhs > 0
union all
select Industry, Pitchers_City, Pitchers_State, 'Anupam' as sharkname from sharktank 
where Anupam_Investment_Amount_in_lakhs > 0
union all
select Industry, Pitchers_City, Pitchers_State, 'Aman' as sharkname from sharktank 
where Aman_Investment_Amount_in_lakhs > 0
union all
select Industry, Pitchers_City, Pitchers_State, 'Peyush' as sharkname from sharktank 
where Peyush_Investment_Amount_in_lakhs > 0
union all
select Industry, Pitchers_City, Pitchers_State, 'Amit' as sharkname from sharktank 
where Amit_Investment_Amount_in_lakhs > 0
union all
select Industry, Pitchers_City, Pitchers_State, 'Ashneer' as sharkname from sharktank 
where Ashneer_Investment_Amount > 0
) as t
group by sharkname
order by unique_industry, unique_location;

select * from sharktank;






-- 10.Explain the concept of indexes in MySQL. How do indexes improve query performance, and what factors should be considered when deciding which columns to index in a database table

-- https://dev.mysql.com/doc/refman/8.0/en/mysql-indexes.html
