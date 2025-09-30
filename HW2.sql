-- *************************************************************
-- Safe updates
-- *************************************************************
set SQL_SAFE_UPDATES=0;
set FOREIGN_KEY_CHECKS=0;

use rest_data;

-- *************************************************************
-- Average Price of Foods at Each Restaurant
-- *************************************************************
select restaurants.name, avg(foods.price) as avg_price
from restaurants
	inner join serves on restaurants.restID = serves.restID
	inner join foods on serves.foodID = foods.foodID
group by restaurants.name
order by avg_price desc;


-- *************************************************************
-- Maximum Food Price at Each Restaurant
-- *************************************************************
select restaurants.name, max(foods.price) as max_price
from restaurants
	inner join serves on restaurants.restID = serves.restID
	inner join foods on serves.foodID = foods.foodID
group by restaurants.name
order by max_price desc;


-- *************************************************************
-- Count of Different Food Types Served at Each Restaurant
-- *************************************************************
select restaurants.name, count(distinct foods.type) as diff_types
from restaurants
	inner join serves on restaurants.restID = serves.restID
	inner join foods on serves.foodID = foods.foodID
group by restaurants.name
order by diff_types desc;


-- *************************************************************
-- Average Price of Foods Served by Each Chef
-- *************************************************************
select chefs.name, avg(foods.price) as avg_price
from chefs
	inner join works on chefs.chefID = works.chefID
	inner join restaurants on works.restID = restaurants.restID
	inner join serves on restaurants.restID = serves.restID
	inner join foods on serves.foodID = foods.foodID
group by chefs.name
order by avg_price desc;


-- *************************************************************
-- Find the Restaurant with the Highest Average Food Price 
-- *************************************************************
select restaurants.name, avg(foods.price) as avg_price
from restaurants
	inner join serves on restaurants.restID = serves.restID
	inner join foods on serves.foodID = foods.foodID
group by restaurants.name
having avg(foods.price) >= all (
	select avg(foods.price)
	from restaurants
		inner join serves on restaurants.restID = serves.restID
		inner join foods on serves.foodID = foods.foodID
	group by restaurants.name)