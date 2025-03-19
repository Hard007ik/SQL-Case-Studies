use campusx;
SELECT *
FROM salaries;

/*1.You're a Compensation analyst employed by a multinational corporation. 
Your Assignment is to Pinpoint Countries who give work fully remotely, for the title
'managers’ Paying salaries Exceeding $90,000 USD*/

SELECT DISTINCT company_location
FROM salaries
WHERE salary_in_usd > 90000 AND job_title LIKE '%Manager%' AND remote_ratio = 100;

/*2.AS a remote work advocate Working for a progressive HR tech startup who place their freshers’ clients IN large tech firms. 
you're tasked WITH 
Identifying top 5 Country Having  greatest count of large(company size) number of companies.*/

select company_location, count(*) as cnt_count
from salaries
where experience_level = 'EN' and company_size='L'
group by company_location
order by cnt_count desc
limit 5;

/*3. Picture yourself AS a data scientist Working for a workforce management platform. 
Your objective is to calculate the percentage of employees. 
Who enjoy fully remote roles WITH salaries Exceeding $100,000 USD, 
Shedding light ON the attractiveness of high-paying remote positions IN today's job market.*/

select
(count(*) * 100)/(select count(*)
from salaries where salary_in_usd>100000) as t 
from salaries 
where remote_ratio=100 and salary_in_usd>100000;

-- OR variable in sql

set @totalCount = (select count(*) from salaries where salary_in_usd>100000);
set @count = (select count(*) from salaries where salary_in_usd>100000 and remote_ratio=100);
set @percentage = round( ( ( (select @count) / (select @totalCount) ) * 100), 2);
select @percentage as 'Percentage';

/*4. Imagine you're a data analyst Working for a global recruitment agency. 
Your Task is to identify the Locations where entry-level average salaries exceed the 
average salary for that job title in market for entry level, helping your agency guide candidates towards lucrative countries.*/

select m.company_location, m.job_title, locationwise_en_avg_salary, market_en_avg_salary from
(select job_title, avg(salary_in_usd) as market_en_avg_salary
from salaries
where experience_level='EN'
group by job_title) as t
join
(select company_location, job_title, avg(salary_in_usd) as locationwise_en_avg_salary
from salaries
where experience_level='EN'
group by job_title, company_location) as m
on t.job_title = m.job_title
where locationwise_en_avg_salary > market_en_avg_salary;

/*5. You've been hired by a big HR Consultancy to look at how much people get paid IN different Countries. 
Your job is to Find out for each job title which
Country pays the maximum average salary. This helps you to place your candidates IN those countries.*/

select *, avg_salary_rank from
(select job_title, company_location, dense_rank() over( partition by job_title order by avg(salary_in_usd) desc) as avg_salary_rank
from salaries
group by job_title, company_location) as t
where avg_salary_rank=1;


/*6.  AS a data-driven Business consultant, you've been hired by a multinational corporation to analyze salary trends 
across different company Locations.
 Your goal is to Pinpoint Locations WHERE the average salary Has consistently 
 Increased over the Past few years (Countries WHERE data is available for 3 years Only(this and pst two years) 
 providing Insights into Locations experiencing Sustained salary growth.*/
 
select year(current_date());

with dumb_tbl as (
select * from salaries where company_location in (
select company_location from (
select company_location, count(distinct work_year) as work_year_cnt, avg(salary_in_usd)
from salaries where work_year>=year(current_date())-3
group by company_location
having work_year_cnt=3
) as t
)
)

select company_location,
max(case when work_year=2022 then avg_sal end) as avg_sal_2022,
max(case when work_year=2023 then avg_sal end) as avg_sal_2023,
max(case when work_year=2024 then avg_sal end) as avg_sal_2024
from (
select company_location, work_year, avg(salary_in_usd) as avg_sal from salaries
group by company_location, work_year
) as m group by company_location having avg_sal_2024>avg_sal_2023 and avg_sal_2023>avg_sal_2022;

/* 7.	Picture yourself AS a workforce strategist employed by a global HR tech startup. 
Your missiON is to determINe the percentage of  fully remote work for each 
experience level IN 2021 and compare it WITH the correspONdINg figures for 2024, 
highlightINg any significant INcreASes or decreASes IN remote work adoptiON
over the years.*/

with 
t1 as
(
select t.experience_level, t.total, m.remote, (m.remote/t.total)*100 as percantage_remote_total_2021 from
(select experience_level, count(*) as total from salaries where work_year=2021 group by experience_level) as t
inner join
(select experience_level, count(*) as remote from salaries where work_year=2021 and remote_ratio=100 group by experience_level) as m
on t.experience_level = m.experience_level
),

t2 as
(
select t.experience_level, t.total, m.remote, (m.remote/t.total)*100 as percantage_remote_total_2024 from
(select experience_level, count(*) as total from salaries where work_year=2024 group by experience_level) as t
inner join
(select experience_level, count(*) as remote from salaries where work_year=2024 and remote_ratio=100 group by experience_level) as m
on t.experience_level = m.experience_level
)

select t1.experience_level,percantage_remote_total_2021, percantage_remote_total_2024  from t1 inner join t2 on t1.experience_level=t2.experience_level;

/* 8. AS a compensatiON specialist at a Fortune 500 company, you're tASked WITH analyzINg salary trends over time. 
Your objective is to calculate the average 
salary INcreASe percentage for each experience level and job title between the years 2023 and 2024, 
helpINg the company stay competitive IN the talent market.*/

select t.experience_level, t.job_title, ((avg_sal_2024-avg_sal_2023)/avg_sal_2023)*100 as pr_sal_2023_2024 from
(select experience_level, job_title, avg(salary_in_usd) as avg_sal_2023 from salaries where work_year=2023 group by experience_level, job_title) as t
inner join 
(select experience_level, job_title, avg(salary_in_usd) as avg_sal_2024 from salaries where work_year=2024 group by experience_level, job_title) as m
on t.experience_level=m.experience_level and t.job_title=m.job_title
order by t.experience_level;

-- OR
with t as (
select experience_level, job_title, work_year, avg(salary_in_usd) as avg_sal from salaries where work_year in (2023, 2024) group by experience_level, job_title, work_year
)

select *, ((avg_sal_2024-avg_sal_2023)/avg_sal_2023)*100 as per_sal_2023_2024 from (
select experience_level, job_title,
max(case when work_year=2023 then avg_sal end) as avg_sal_2023,
max(case when work_year=2024 then avg_sal end) as avg_sal_2024
from t group by experience_level, job_title
)as t2
where ((avg_sal_2024-avg_sal_2023)/avg_sal_2023)*100 is not null;

 
/* 9. You're a database administrator tasked with role-based access control for a company's employee database. Your goal is to implement a security measure where employees
 in different experience level (e.g.Entry Level, Senior level etc.) can only access details relevant to their respective experience_level, ensuring data 
 confidentiality and minimizing the risk of unauthorized access.*/

select distinct experience_level from salaries;


create user 'Entry_level'@'%' identified by 'EN';
create user 'Mid_level'@'%' identified by 'MI';
create user 'Senior_level'@'%' identified by 'SE';
create user 'Expert_level'@'%' identified by 'EX';

CREATE VIEW entry_level as
(
select * from salaries where experience_level='EN'
);

CREATE VIEW mid_level as
(
select * from salaries where experience_level='MI'
);

CREATE VIEW senior_level as
(
select * from salaries where experience_level='SE'
);

CREATE VIEW expert_level as
(
select * from salaries where experience_level='EX'
);

show privileges;

grant select on campusx.entry_level to 'Entry_level'@'%';
grant select on campusx.mid_level to 'Mid_level'@'%';
grant select on campusx.senior_level to 'Senior_level'@'%';
grant select on campusx.expert_level to 'Expert_level'@'%';



/* 10.	You are working with an consultancy firm, your client comes to you with 
certain data and preferences such as 
( their year of experience , their employment type, company location and company size )  
and want to make an transaction into different domain in data industry
(like  a person is working as a data analyst and want to move to some other domain such 
as data science or data engineering etc.)
your work is to  guide them to which domain they should switch to base on  the input they provided, 
so that they can now update thier knowledge as  per the suggestion/.. 
The Suggestion should be based on average salary.*/

DELIMITER //
CREATE PROCEDURE GetAvgSalary(IN exp_level varchar(2), IN emp_type varchar(3), IN comp_loc varchar(2), IN comp_size varchar(2))
BEGIN
SELECT job_title, experience_level, company_location, company_size, employment_type, AVG(salary_in_usd) AS avg_sal
FROM salaries
WHERE experience_level=exp_level AND employment_type=emp_type AND company_location=comp_loc AND company_size=comp_size
GROUP BY job_title, experience_level, company_location, company_size, employment_type
ORDER BY avg_sal DESC;
END //
DELIMITER ;

call GetAvgSalary('EN','FT','AU','M');

drop procedure GetAvgSalary;

/*11.As a market researcher, your job is to Investigate the job market for a company that analyzes workforce data. 
Your Task is to know how many people were
 employed IN different types of companies AS per their size IN 2021.*/
 
-- Select company size and count of employees for each size.

select company_size, count(*)
from salaries
where work_year=2021
group by company_size;

/*12.Imagine you are a talent Acquisition specialist Working for an International recruitment agency. 
Your Task is to identify the top 3 job titles that 
command the highest average salary Among part-time Positions IN the year 2023.*/

select job_title, avg(salary_in_usd) as avg_sal
from salaries
where work_year=2023 and employment_type='PT'
group by job_title
order by avg_sal desc
limit 3;

/*3.As a database analyst you have been assigned the task to Select Countries where average mid-level 
salary is higher than overall mid-level salary for the year 2023.*/

set @salary_overall = (select avg(salary_in_usd)
from salaries 
where work_year=2023 and experience_level='MI');

select @salary_overall;

select company_location, avg(salary_in_usd)
from salaries where work_year=2023 and experience_level='MI'
group by company_location
having avg(salary_in_usd) > @salary_overall;


/*14.As a database analyst you have been assigned the task to Identify the company locations with the highest and lowest average salary for 
senior-level (SE) employees in 2023.*/

with t as
(
select company_location, avg(salary_in_usd) as avg_sal
from salaries
where work_year=2023 and experience_level='SE'
group by company_location
)

select company_location,  avg_sal
from t
where avg_sal=(select max(avg_sal) from t)
or avg_sal=(select min(avg_sal) from t);



/*15. You're a Financial analyst Working for a leading HR Consultancy, and your Task is to Assess the 
annual salary growth rate for various job titles. 
By Calculating the percentage Increase IN salary FROM previous year to this year, you aim to provide 
valuable Insights Into salary trends WITHIN different job roles.*/

with t1 as (
select job_title, avg(salary_in_usd) as avg_sal_2023
from salaries
where work_year=2023
group by job_title
),

t2 as (
select job_title, avg(salary_in_usd) as avg_sal_2024
from salaries
where work_year=2024
group by job_title
)

select t1.job_title, avg_sal_2023, t2.avg_sal_2024, round((t2.avg_sal_2024-t1.avg_sal_2023)*100/NULLIF(t1.avg_sal_2023, 0), 2) as sal_inc_pct
from t1 
inner join t2
on t1.job_title=t2.job_title;


 /*16. You've been hired by a global HR Consultancy to identify Countries experiencing 
 significant salary growth for entry-level roles. Your task is to list the top three 
 Countries with the highest salary growth rate FROM 2020 to 2023, 
 helping multinational Corporations identify  Emerging talent markets.*/
 
select t1.company_location, t1.sal_2020, t2.sal_2023, round((t2.sal_2023-t1.sal_2020)*100/t1.sal_2020, 2) as sal_inc_pct
from 
(select company_location, avg(salary_in_usd) as sal_2020
from salaries
where work_year=2020 and experience_level='EN' 
group by company_location
) as t1
inner join 
(select company_location, avg(salary_in_usd) as sal_2023
from salaries
where work_year=2023 and experience_level='EN' 
group by company_location
) as t2
on t1.company_location=t2.company_location
order by sal_inc_pct desc
limit 3;



/* 17.Picture yourself as a data architect responsible for database management. 
Companies in US and AU(Australia) decided to create a hybrid model for employees 
 they decided that employees earning salaries exceeding $90000 USD, will be given work from home. 
 You now need to update the remote work ratio for eligible employees,
 ensuring efficient remote work management while implementing 
 appropriate error handling mechanisms for invalid input parameters.*/

CREATE TABLE SAL2 AS SELECT * FROM salaries;

DELIMITER //
CREATE PROCEDURE UpdateWork()
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		ROLLBACK;
        SELECT 'ERROR: Could not update remote work ratio' as message;
    END;

START TRANSACTION;

UPDATE sal2 
SET remote_ratio=100
WHERE 
company_location IN ('US', 'AU')
AND salary_in_usd > 90000;

COMMIT;

SELECT 'Remote work ration updated successfully' AS message;

END //
DELIMITER ;
 
call UpdateWork();


 
/* 18. In year 2024, due to increase demand in data industry , there was  increase in salaries of data field employees.
                   Entry Level-35%  of the salary.
                   Mid junior – 30% of the salary.
                   Immediate senior level- 22% of the salary.
                   Expert level- 20% of the salary.
                   Director – 15% of the salary.
you have to update the salaries accordingly and update it back in the original database. */

update sal2 set salary_in_usd = 
	case
		when experience_level='EN' then salary_in_usd * 1.35
        when experience_level='MI' then salary_in_usd * 1.30
        when experience_level='SE' then salary_in_usd * 1.22
        when experience_level='EX' then salary_in_usd * 1.20
        when experience_level='DX' then salary_in_usd * 1.15
        else salary_in_usd
    end
    where work_year=2024;
    

/*19. You are a researcher and you have been assigned the task to Find the year 
with the highest average salary for each job title.*/

with avg_sal_per_year as (
select job_title, work_year, avg(salary_in_usd) as avg_sal
from salaries
group by job_title, work_year)

select job_title, work_year, avg_sal from (
select job_title, work_year, avg_sal, rank() over(partition by job_title order by avg_sal) as rank_sal
from avg_sal_per_year) as t
where rank_sal=1;
    
/*20. You have been hired by a market research agency where you been assigned the task to 
show the percentage of different employment type (full time, part time) in 
Different job roles, in the format where each row will be job title, each column will be type 
of employment type and  cell value  for that row and column will show 
the % value*/

select distinct employment_type from salaries;

select job_title,
round( (sum( case when employment_type='FT' then 1 else 0 end ) / count(*)) * 100 , 2) as pct_full_time,
round( (sum( case when employment_type='CT' then 1 else 0 end ) / count(*)) * 100 , 2) as pct_contract,
round( (sum( case when employment_type='PT' then 1 else 0 end ) / count(*)) * 100 , 2) as pct_part_time,
round( (sum( case when employment_type='FL' then 1 else 0 end ) / count(*)) * 100 , 2) as pct_freelance
from salaries
group by job_title;


SELECT *
FROM salaries;

