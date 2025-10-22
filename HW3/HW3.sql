use hw3;
SET SQL_SAFE_UPDATES = 0;

-- I realized I needed to alter the tables to change the column names and to set the primary and foreign keys
-- I also needed to set the constraints
describe products;

alter table products
change column `ï»¿Column1` pid INT,
change column `Column2` name ENUM(
  'Printer', 'Ethernet Adapter', 'Desktop', 'Hard Drive', 'Laptop',
  'Router', 'Network Card', 'Super Drive', 'Monitor') NOT NULL,
change column `Column3` category ENUM('Peripheral', 'Networking', 'Computer') NOT NULL,
change column `Column4` description VARCHAR(300);

alter table products
add primary key (pid);

describe merchants;

alter table merchants
change column `ï»¿Column1` mid INT,
change column `Column2` name VARCHAR(50),
change column `Column3` city VARCHAR(50),
change column `Column4` state VARCHAR(50);

alter table merchants
add primary key (mid);

describe sell;

alter table sell
change column `ï»¿Column1` mid INT,
change column `Column2` pid INT,
change column `Column3` price DECIMAL(10,2),
change column `Column4` quantity_available INT;

alter table sell
add primary key (mid, pid),
add foreign key (mid) REFERENCES merchants(mid),
add foreign key (pid) REFERENCES products(pid),
add constraint chk_price CHECK (price BETWEEN 0 AND 100000),
add constraint chk_quantity CHECK (quantity_available BETWEEN 0 AND 1000);

alter table customers
change column `ï»¿Column1` cid INT,
change column `Column2` fullname VARCHAR(100),
change column `Column3` city VARCHAR(100),
change column `Column4` state VARCHAR(20);

alter table customers
add primary key (cid);

alter table orders
change column `ï»¿Column1` oid INT,
change column `Column2` shipping_method ENUM('UPS','FedEx','USPS'),
change column `Column3` shipping_cost DECIMAL(10,2);

alter table orders
add primary key (oid);

alter table orders
add constraint chk_shipping_cost CHECK (shipping_cost BETWEEN 0 AND 500);

describe place;

alter table place
change column `ï»¿Column1` cid INT,
change column `Column2` oid INT,
change column `Column3` order_date VARCHAR(20);

update place
set order_date = str_to_date(order_date, '%m/%d/%Y');

alter table place
modify column order_date DATE;

alter table place
add primary key (cid, oid),
add constraint fk_place_customer FOREIGN KEY (cid) REFERENCES customers(cid),
add constraint fk_place_order FOREIGN KEY (oid) REFERENCES orders(oid);

alter table contain
change column `ï»¿Column1` oid INT,
change column `Column2` pid INT;

alter table contain
add primary key (oid, pid),
add constraint fk_contain_order foreign key (oid) references orders(oid),
add constraint fk_contain_product foreign key (pid) references products(pid);


-- question 1
select p.name AS product_name, m.name AS merchant_name
from products p
join sell s ON p.pid = s.pid
join merchants m ON s.mid = m.mid
where s.quantity_available = 0;

-- question 2
select p.name as product_name, p.description as product_description
from products p
left join sell s on p.pid = s.pid
where s.pid is null;

-- question 3
select COUNT(*) AS num_customers
from (
    select pl.cid
    from place pl
    join contain co ON pl.oid = co.oid
    join products p ON co.pid = p.pid
    group by pl.cid
	having
        SUM(p.name LIKE '%SATA%') > 0     
        AND SUM(p.name LIKE '%Router%') = 0  
) AS subquery;

-- question 4
update sell s
join merchants m ON s.mid = m.mid
join products p ON s.pid = p.pid
set s.price = s.price * 0.8
where m.name = 'HP'
  AND p.category = 'Networking';
  
-- question 5
select 
    p.name AS product_name,
    s.price AS price
from customers c
join place pl ON c.cid = pl.cid
join contain co ON pl.oid = co.oid
join products p ON co.pid = p.pid
join sell s ON s.pid = p.pid
where c.fullname = 'Uriel Whitney';

-- question 6
select 
    m.name AS company,
    YEAR(pl.order_date) AS order_year,
    SUM(s.price) AS total_sales
from merchants m
join sell s ON m.mid = s.mid
join contain co ON s.pid = co.pid
join place pl ON co.oid = pl.oid
group by m.name, YEAR(pl.order_date)
order by m.name, order_year;

-- question 7
select company, order_year, total_sales
from (
    select 
        m.name AS company,
        YEAR(pl.order_date) AS order_year,
        SUM(s.price) AS total_sales
    from merchants m
    join sell s ON m.mid = s.mid
    join contain co ON s.pid = co.pid
    join place pl ON co.oid = pl.oid
    group by m.name, YEAR(pl.order_date)
) AS annual_sales
order by total_sales desc
limit 1;

-- question 8
select shipping_method, AVG(shipping_cost) AS avg_cost
from orders
group by shipping_method
order by avg_cost
limit 1;

-- question 9
select 
    m.name AS company,
    p.category,
    SUM(s.price) AS total_revenue
from merchants m
join sell s ON m.mid = s.mid
join contain co ON s.pid = co.pid
join place pl ON co.oid = pl.oid
join products p ON s.pid = p.pid
group by m.name, p.category;

select t1.company, t1.category, t1.total_revenue
from (
    select 
        m.name AS company,
        p.category,
        SUM(s.price) AS total_revenue
    from merchants m
    join sell s ON m.mid = s.mid
    join contain co ON s.pid = co.pid
    join place pl ON co.oid = pl.oid
    join products p ON s.pid = p.pid
    group by m.name, p.category
) AS t1
where t1.total_revenue = (
    select MAX(t2.total_revenue)
    from (
        select 
            m.name AS company,
            p.category,
            SUM(s.price) AS total_revenue
        from merchants m
        join sell s ON m.mid = s.mid
        join contain co ON s.pid = co.pid
        join place pl ON co.oid = pl.oid
        join products p ON s.pid = p.pid
        group by m.name, p.category
    ) AS t2
    where t2.company = t1.company
);

-- question 10
with customer_totals AS (
    select  
        m.name AS company,
        c.fullname AS customer,
        SUM(s.price) AS total_spent
    from merchants m
    join sell s ON m.mid = s.mid
    join contain co ON s.pid = co.pid
    join place pl ON co.oid = pl.oid
    join customers c ON pl.cid = c.cid
    group by m.name, c.cid
)
-- get the maximum spenders
select ct.company, ct.customer, ct.total_spent, 'max' AS type
from customer_totals ct
join (
    select company, MAX(total_spent) AS max_spent
    from customer_totals
    group by company
) AS mx 
  ON ct.company = mx.company AND ct.total_spent = mx.max_spent

UNION ALL

-- get the minimum spenders
select ct2.company, ct2.customer, ct2.total_spent, 'min' AS type
from customer_totals ct2
join (
    select company, MIN(total_spent) AS min_spent
    from customer_totals
    group by company
) AS mn
  ON ct2.company = mn.company AND ct2.total_spent = mn.min_spent;
