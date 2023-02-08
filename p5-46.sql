функция(аргумент) over (partition by ... order by ...)

customer_id | sum(amount)
1				5
1				2
1				3
1				5
2				3
2				1
2				3
group by 
1				15
2				7
partition by 
1				5		15
1				2		15
1				3		15
1				5		15
2				3		7
2				1		7
2				3		7

from 
on 
join 
where 
group by 
having 
over 
select customer_id, amount, окно

============= оконные функции =============

1. Вывести ФИО пользователя и название третьего фильма, который он брал в аренду.
* В подзапросе получите порядковые номера для каждого пользователя по дате аренды
* Задайте окно с использованием предложений over, partition by и order by
* Соедините с customer
* Соедините с inventory
* Соедините с film
* В условии укажите 3 фильм по порядку

explain analyze --1934
select customer_id, f.title
from (
	select customer_id, array_agg(inventory_id)
	from (
		select customer_id, rental_date, inventory_id
		from rental 
		order by customer_id, rental_date) t 
	group by 1) t
join inventory i on i.inventory_id = t.array_agg[3]
join film f on f.film_id = i.film_id

explain analyze --2108
select customer_id, f.title
from (
	select customer_id, rental_date, inventory_id, row_number() over (partition by customer_id order by rental_date)
	from rental) t
join inventory i on i.inventory_id = t.inventory_id
join film f on f.film_id = i.film_id	
where row_number = 3

1.1. Выведите таблицу, содержащую имена покупателей, арендованные ими фильмы и средний платеж 
каждого покупателя
* используйте таблицу customer
* соедините с paymen
* соедините с rental
* соедините с inventory
* соедините с film
* avg - функция, вычисляющая среднее значение
* Задайте окно с использованием предложений over и partition by

select c.last_name, f.title, amount, avg(p.amount) over (partition by c.customer_id)
from customer c
join payment p on p.customer_id = c.customer_id
join rental r on p.rental_id = r.rental_id
join inventory i on i.inventory_id = r.rental_id
join film f on f.film_id = i.film_id

select c.last_name, f.title, amount, 
	avg(p.amount) over (partition by c.customer_id),
	count(p.amount) over (partition by c.customer_id),
	sum(p.amount) over (partition by c.customer_id),
	min(p.amount) over (partition by c.customer_id),
	max(p.amount) over (partition by c.customer_id),
	avg(p.amount) over (),
	count(p.amount) over (),
	sum(p.amount) over (),
	min(p.amount) over (),
	max(p.amount) over ()
from customer c
join payment p on p.customer_id = c.customer_id
join rental r on p.rental_id = r.rental_id
join inventory i on i.inventory_id = r.rental_id
join film f on f.film_id = i.film_id

select customer_id, sum(amount) * 100 / (select sum(amount) from payment) 
from payment 
group by 1

select customer_id, sum(amount) * 100 / sum(sum(amount)) over ()
from payment 
group by 1

select c.last_name, f.title, amount, date_trunc('month', p.payment_date),
	avg(p.amount) over (partition by c.customer_id),
	count(p.amount) over (partition by c.customer_id),
	sum(p.amount) over (partition by c.customer_id),
	min(p.amount) over (partition by c.customer_id),
	max(p.amount) over (partition by c.customer_id),
	avg(p.amount) over (),
	count(p.amount) over (),
	sum(p.amount) over (partition by c.customer_id, date_trunc('month', p.payment_date)),
	min(p.amount) over (),
	max(p.amount) over ()
from customer c
join payment p on p.customer_id = c.customer_id
join rental r on p.rental_id = r.rental_id
join inventory i on i.inventory_id = r.rental_id
join film f on f.film_id = i.film_id

-- filter 

select customer_id, sum(amount) over (), 
	sum(amount) filter (where amount <= 5) over (partition by customer_id),
	sum(amount) filter (where amount > 5) over (partition by customer_id)
from payment 

-- формирование накопительного итога

explain analyze

select customer_id, payment_date, amount, sum(amount) over (partition by customer_id order by payment_date)
from payment 

select customer_id, payment_date, amount, avg(amount) over (partition by customer_id order by payment_date)
from payment 

select customer_id, payment_date::date, amount, sum(amount) over (partition by customer_id order by payment_date::date)
from payment 

select customer_id, payment_date::date, amount, avg(amount) over (partition by customer_id order by payment_date::date)
from payment 

-- работа функций lead и lag

select customer_id, payment_date, 
	lag(amount) over (partition by customer_id order by payment_date),
	amount, 
	lead(amount) over (partition by customer_id order by payment_date)
from payment 

select customer_id, payment_date, 
	amount, lag(amount) over (partition by customer_id order by payment_date),
	amount - lag(amount) over (partition by customer_id order by payment_date)
from payment 

select customer_id, payment_date, 
	lag(amount, 3) over (partition by customer_id order by payment_date),
	amount, 
	lead(amount, 5) over (partition by customer_id order by payment_date)
from payment 

select customer_id, payment_date, 
	lag(amount, 3, 0.) over (partition by customer_id order by payment_date),
	amount, 
	lead(amount, 5, 0.) over (partition by customer_id order by payment_date)
from payment 

select date_trunc('month', payment_date), sum (amount),
	sum (amount) - lag(sum (amount)) over (order by date_trunc('month', payment_date))
from payment 
group by 1

-- работа с рангами и порядковыми номерами

select customer_id, payment_date::date, amount, 
	row_number() over (partition by customer_id order by payment_date::date, amount),
	rank() over (partition by customer_id order by payment_date::date),
	dense_rank() over (partition by customer_id order by payment_date::date)
from payment 

select *
from (
	select customer_id, payment_date::date, amount, 
		row_number() over (partition by customer_id order by payment_date::date),
		rank() over (partition by customer_id order by payment_date::date),
		dense_rank() over (partition by customer_id order by payment_date::date)
	from payment) t
where row_number between 5 and 7

select *
from (
	select customer_id, payment_date::date, amount, 
		row_number() over (partition by customer_id order by payment_date::date),
		rank() over (partition by customer_id order by payment_date::date),
		dense_rank() over (partition by customer_id order by payment_date::date)
	from payment) t
where dense_rank between 5 and 7

1 - 10
2,3 - 10.1
4 - 10.2

1 - 1 
2,3 - 2
4 - 4
where rank <=3

1 - 1 
2,3 - 2
4 - 3
where dense_rank <=3

-- last_value / first_value / nth_value

использовать last_value не желательно.

explain analyze --1480
select distinct on (customer_id) customer_id, payment_date, amount
from payment
order by customer_id, payment_date desc

explain analyze --744
select payment_id, customer_id, payment_date, amount
from payment
where (customer_id, payment_date) in (select customer_id, max(payment_date) from payment group by customer_id)

explain analyze --1987
select distinct customer_id, 
	first_value(payment_date) over (partition by customer_id order by payment_date desc),
	first_value(amount) over (partition by customer_id order by payment_date desc),
	first_value(rental_id) over (partition by customer_id order by payment_date desc)
from payment

explain analyze --1786
select *
from (
	select *, first_value(payment_date) over (partition by customer_id order by payment_date desc)
	from payment) t
where payment_date = first_value

использовать last_value не желательно.
использовать last_value не желательно.
использовать last_value не желательно.
использовать last_value не желательно.

select distinct customer_id, payment_date,
	last_value(payment_date) over (partition by customer_id order by payment_date),
	last_value(amount) over (partition by customer_id order by payment_date),
	last_value(rental_id) over (partition by customer_id order by payment_date)
from payment
order by 1

select customer_id, payment_date, amount, rental_id
from payment
order by customer_id

select *
from (
	select *, last_value(payment_date) over (partition by customer_id)
	from (
		select *
		from payment
		order by customer_id, payment_date) p) t
where payment_date = last_value

select *
from (
	select *, last_value(payment_date) over (partition by customer_id order by payment_date
		rows between unbounded preceding and unbounded following)
	from payment) t
where payment_date = last_value

explain analyze --1786 / 13.7
select *
from (
	select *, nth_value(payment_date, 10) over (partition by customer_id order by payment_date)
	from payment) t
where payment_date = nth_value

explain analyze --1786 / 12
select *
from (
	select *, row_number() over (partition by customer_id order by payment_date)
	from payment) t
where row_number = 10

--алиасы

select c.last_name, f.title, amount, date_trunc('month', p.payment_date),
	avg(p.amount) over w_1,
	count(p.amount) over w_1,
	sum(p.amount) over w_1,
	min(p.amount) over w_1,
	max(p.amount) over w_1,
	avg(p.amount) over w_2,
	count(p.amount) over w_2,
	sum(p.amount) over w_3,
	min(p.amount) over w_3,
	max(p.amount) over w_3
from customer c
join payment p on p.customer_id = c.customer_id
join rental r on p.rental_id = r.rental_id
join inventory i on i.inventory_id = r.rental_id
join film f on f.film_id = i.film_id
window w_1 as (partition by c.customer_id),
	w_2 as (partition by c.customer_id order by p.payment_date),
	w_3 as (partition by c.customer_id, date_trunc('month', p.payment_date))
order by 1
	
============= общие табличные выражения =============

2.  При помощи CTE выведите таблицу со следующим содержанием:
Название фильма продолжительностью более 3 часов и к какой категории относится фильм
* Создайте CTE:
 - Используйте таблицу film
 - отфильтруйте данные по длительности
 * напишите запрос к полученной CTE:
 - соедините с film_category
 - соедините с category

with cte1 as (
	select *
	from film 
	where length > 180),
cte2 as (
	select *
	from cte1 
	join film_category fc on fc.film_id = cte1.film_id)
select cte2.title, c."name"
from cte2
join category c on c.category_id = cte2.category_id

with cte as (
	select *, row_number() over (partition by customer_id order by payment_date)
	from payment
	where customer_id < 3)
select c1.customer_id, c2.customer_id, c1.amount - c2.amount
from cte c1
join cte c2 on c1.row_number = c2.row_number

select 
from (
	select *, row_number() over (partition by customer_id order by payment_date)
	from payment
	where customer_id < 3) t 
join ( 
	select *, row_number() over (partition by customer_id order by payment_date)
	from payment
	where customer_id < 3) t2 on t.row_number = t2.row_number

	
create table b (
	id int,
	val int)
	
with c as (
	select customer_id, amount
	from payment)
insert into b 
select * 
from c

drop table b

2.1. Выведите фильмы, с категорией начинающейся с буквы "C"
* Создайте CTE:
 - Используйте таблицу category
 - Отфильтруйте строки с помощью оператора like 
* Соедините полученное табличное выражение с таблицей film_category
* Соедините с таблицей film
* Выведите информацию о фильмах:
title, category."name"

select version() --14 / 10

explain analyze --91.33 / 93.03
with c1 as (
	with c2 as (
		select *
		from category 
		where left(name, 1) = 'C')
	select *
	from c2
	join film_category fc on fc.category_id = c2.category_id)
select f.title, c1.name
from c1
join film f on f.film_id = c1.film_id

============= общие табличные выражения (рекурсивные) =============
 
 3.Вычислите факториал
 + Создайте CTE
 * стартовая часть рекурсии (т.н. "anchor") должна позволять вычислять начальное значение
 *  рекурсивная часть опираться на данные с предыдущей итерации и иметь условие остановки
 + Напишите запрос к CTE

with recursive r as (
	--стартовая часть
	select 1 as i, 1 as factorial
	union 
	--рекурсивная часть
	select i + 1 as i, factorial * (i + 1) as factorial
	from r
	where i < 10)
select *
from r

with recursive r as (
	--стартовая часть
	select *, 1 as level
	from "structure" s
	where unit_id = 95
	union 
	--рекурсивная часть
	select s.*, level + 1 as level
	from r 
	join "structure" s on r.parent_id = s.unit_id)
select *
from r

with recursive r as (
	--стартовая часть
	select *, 1 as level
	from "structure" s
	where unit_id = 18
	union 
	--рекурсивная часть
	select s.*, level + 1 as level
	from r 
	join "structure" s on s.parent_id = r.unit_id)
select count(*)
from r
join "position" p on p.unit_id = r.unit_id 
join employee e on e.pos_id = p.pos_id

3.2 Работа с рядами.

explain analyse --3.57
with recursive r as (
	--стартовая часть
	select '01.01.2022'::date x
	union 
	--рекурсивная часть
	select x + 1 as x
	from r
	where x < '31.12.2022')
select *
from r

explain analyse --12.51
select x::date
from generate_series('01.01.2022'::date, '31.12.2022'::date, interval '1 day') x

explain analyse --3.57
with recursive r as (
	--стартовая часть
	select 1 x
	union 
	--рекурсивная часть
	select x + 1 as x
	from r
	where x < 100)
select *
from r

explain analyse --1
select x
from generate_series(1, 100, 1) x

select date_trunc('month', payment_date), sum (amount),
	sum (amount) - lag(sum (amount)) over (order by date_trunc('month', payment_date))
from payment 
group by 1

explain analyze --5027 / 11.3


explain analyze --4937 / 11.2
select x, coalesce(t.sum, 0), coalesce(coalesce(t.sum, 0) - lag(coalesce(t.sum, 0), 3, 0.) over (order by x), 0)
from generate_series((select min(date_trunc('month', payment_date)) x from payment),
	(select max(date_trunc('month', payment_date)) from payment ), interval '1 month') x
left join (
	select date_trunc('month', payment_date), sum(amount)
	from payment 
	group by 1) t on t.date_trunc = x
order by x


create table b (
	val1 int[],
	val1 numeric[] check(array_length(val1, 1) > 1),
)

lag(значение, шаг, значение по умолчанию) over ()
lead() over ()

select payment_date, date_trunc('QUARTER', payment_date)
from payment 

select payment_date, date_part('isodow', payment_date)
from payment 