-- use walmart_db

-- 
SELECT * FROM 
	walmart 
limit 10;

-- 
select 
	count(*) 
from 
	walmart;

--
select 
distinct 
	payment_method 
from 
	walmart;

--
select 
	payment_method, 
    count(*)  
from 
	walmart 
group by 
	payment_method;

--
select 
	count(distinct branch) 
from 
	walmart; 


select 
	max(quantity) 
from 
	walmart;
    

select 
	min(quantity) 
from 
	walmart;


-- 1. difference payment method and number of transactions, number of qty sold
   select 
	payment_method, 
	count(*) as no_of_transactions, 
	sum(quantity) as no_qty_sold
   from 
		walmart 
   group by 
		payment_method 
   order by 
		no_qty_sold 
   desc ;


-- 2. the highest-rated category in each branch, displaying the branch, category avg rating
	with cte as (
		select branch, category, 
		cast(avg(rating) as decimal(5, 2)) as avg_ratings,
		rank() over(partition by branch order by avg(rating) desc) as rank_position
    from 
		walmart
    group by 
		branch, category
    )
    
    select 
		branch, 
        category, 
        avg_ratings, 
        rank_position
    from 
		cte
    where 
		rank_position = 1;
 
 
-- 3. identify the business day for each branch based on the number of transactions
	with BranchDailyTransactions as (
		select 
			branch, 
            dayname(date) as day_name,
			count(*) as no_transactions,
			rank() over(partition by branch order by count(*) desc) as rank_position
		from 
			walmart
		group by 
			branch, 
			day_name
    )

    select 
		branch, 
        day_name, 
        no_transactions, 
        rank_position
    from 
		BranchDailyTransactions
    where 
		rank_position = 1
    order by 
		branch, 
        rank_position;


-- 4. total qty of items sold per payment method, list payment_method and total_qty
	select 
		payment_method, 
        count(*) as no_of_payments, 
        sum(quantity) as no_qty_sold
    from 
		walmart
    group by 
		payment_method;


-- 5. determine the average, min, and max rating of category for each city,
--    list the city, avg_rating, min_rating and max_rating
	select 
		city, 
        category, 
		min(rating) as min_rating, 
		max(rating) as max_rating, 
		cast(avg(rating) as decimal(10, 2)) as avg_rating
    from 
		walmart
    group by 
		city, 
        category;

    
-- 6. calculate the total profit for each category by considering total_profit as 
-- (unit_price * quantity * profit_margin), list category and total_profit, ordered from highest to lowest profit
	select 
		category, 
		cast(sum(unit_total) as decimal(10, 2)) as revenue,
		cast(sum(unit_total * profit_margin) as decimal(10, 2)) as profit
    from 
		walmart
    group by 
		category;
    
    
-- 7. determine the most common payment method for each branch
-- display branch and preferred_payment_method
	with cte as(
		select 
			branch, 
			payment_method, 
			count(*) as total_transaction,
			rank() over(partition by branch order by count(*) desc) as branch_rank
		from 
			walmart
		group by 
			branch, 
            payment_method
    )
    
    select * from 
		cte 
	where 
		branch_rank = 1;
    
    
-- 8. categorize sales into 3 group Morning, Afternoon, Evening
-- find out which of the shift and number of invoices
	select 
		branch,
	case
		when hour(time(time)) < 12 then 'Morning'
		when hour(time(time)) between 12 and 17 then 'Afternoon'
		else 'Evening'
	end as day_time, 
		count(*) as number_of_invoices
	from 
		walmart
	group by 
		branch, 
		day_time
	order by 
		branch, 
		number_of_invoices 
	desc;

-- 	   select branch, 
--     sum(unit_total) as revenue 
--     from walmart
--     group by branch;
--     
--     select *,
--     year(date) as formated_date
--     from walmart;

--  9. identify the difference between revenue compared to last year 
-- (current year 2023 and last year 2022)
	with revenue_2022 as (
    select 
		branch, 
        sum(unit_total) as revenue
    from 
		walmart
    where 
		year(date) = 2022
    group by 
		branch
    ),
    
    revenue_2023 as (
		select 
        branch, 
        sum(unit_total) as revenue
    from 
		walmart
    where 
		year(date) = 2023
    group by 
		branch
    )
    
    select 
		r2022.branch,
		r2022.revenue as last_year_revenue,
		r2023.revenue as current_year_revenue
    from 
		revenue_2022 as r2022
    join 
		revenue_2023 as r2023
    on 
		r2022.branch = r2023.branch
    order by 
		branch 
	asc;
    
    
-- 10. identify 5 branch with highest decrese ratio in
-- revenue compare to last year (current year 2023 and last year 2022)
	with revenue_2022 as (
		select 
			branch,
			sum(unit_total) as revenue
		from 
			walmart
		where
			year(date) = 2022
		group by
			branch
	),
    
    revenue_2023 as (
		select 
			branch, 
			sum(unit_total) as revenue
		from 
			walmart
		where 
			year(date) = 2023
		group by 
			branch
	)
    
    select 
		lys.branch, 
		lys.revenue as last_year_revenue,
		cys.revenue as current_year_revenue,
		round((lys.revenue - cys.revenue) / lys.revenue * 100, 2) as rev_decrease_ratio
    from
		revenue_2022 as lys
    join 
		revenue_2023 as cys
    on 
		lys.branch = cys.branch
    where 
		lys.revenue > cys.revenue
    order by 
		rev_decrease_ratio 
	desc
	limit 5;
    
    
-- 11. identify 5 branch with highest increase ratio in
-- revenue compare to last year (current year 2023 and last year 2022)
    with revenue_2022 as (
		select 
			branch, 
			sum(unit_total) as revenue
		from 
			walmart
		where
			year(date) = 2022
		group by 
			branch
    ),
    
    revenue_2023 as(
		select
			branch, 
			sum(unit_total) as revenue
		from 
			walmart
		where
			year(date) = 2023
		group by 
			branch
    )
    
		select
			lys.branch, 
			lys.revenue as last_year_revenue,
			cys.revenue as current_year_revenue,
			round((cys.revenue - lys.revenue) / lys.revenue * 100, 2) as rev_increase_ratio
		from 
			revenue_2022 as lys
		join 
			revenue_2023 as cys
		on 
			lys.branch = cys.branch
		where 
			cys.revenue > lys.revenue
		order by
			rev_increase_ratio
		desc 
        limit 5;


--  12. identify the difference between revenue compared to each year of months 
-- (current year 2023 and last year 2022)
	with revenue_2022 as (
		select 
			branch, 
			month(date) as month, 
			sum(unit_total) as revenue
		from 
			walmart
		where 
			year(date) = 2022
		group by 
			branch, 
            month(date)
    ),
    
    revenue_2023 as (
		select 
			branch, 
			month(date) as month, 
			sum(unit_total) as revenue
		from 
			walmart
		where 
			year(date) = 2023
		group by 
			branch, 
            month(date)
    )
    
	select 
		r2022.branch,
		r2022.revenue as last_year_revenue,
		r2023.revenue as current_year_revenue
    from 
		revenue_2022 as r2022
    join 
		revenue_2023 as r2023
	on 
		r2022.branch = r2023.branch AND r2022.month = r2023.month
	order by
		r2022.branch, r2022.month;


-- 13. Compare the revenue generated for each branch during the same months in both 2022 and 
-- 2023, displaying the data even if revenue is missing for 2023.
with revenue_2022 as (
    select 
        branch, 
        month(date) as month,
        sum(unit_total) as last_year_month
    from 
        walmart
    where 
        year(date) = 2022
    group by 
        branch, month(date)
), 
revenue_2023 as (
    select 
        branch, 
        month(date) as month,
        SUM(unit_total) as current_year_month
    from 
        walmart
    where 
        year(date) = 2023
    group by 
        branch, month(date)
)
select 
    r2022.branch,
    r2022.month,
    r2022.last_year_month,
    r2023.current_year_month
from  
    revenue_2022 as r2022
left join  
    revenue_2023 as r2023
on
	r2022.branch = r2023.branch and r2022.month = r2023.month
order by 
    r2022.branch, r2022.month;


-- 14. Identify the revenue generated for each branch during the same months in both 2022 and 
-- 2023, ensuring that only months with data available for both years are considered.
	with revenue_2022 as(
		select 
        branch, 
        month(date) as month,
        sum(unit_total) as last_year_month
	from 
		walmart
	where
		year(date) = 2022
	group by 
		branch, month(date)
	),
    
    revenue_2023 as (
		select 
			branch, 
        month(date) as month,
			sum(unit_total) as current_year_month
        from 
			walmart
		where 
			year(date) = 2023
		group by
			branch, month(date)
	)
    
    select
		r2022.branch, 
        r2022.month, 
        r2022.last_year_month,
        r2023.current_year_month
	from 
		revenue_2022 as r2022
	left join 
		revenue_2023 as r2023
	on 
		r2022.branch = r2023.branch and r2022.month = r2023.month
	where
		r2022.last_year_month is not null and r2023.current_year_month is not null
	order by
		r2022.branch, r2023.month;


    
    
    
    
    
    
    
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   

    