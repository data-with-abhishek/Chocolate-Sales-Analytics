--  Repeat vs New Customers (Only the customers who made more than 15 orders will considered as repeat Customers)
--===================================================================================================================

with customer_type as (
	select
		customer_id,
		case
			when count(distinct order_id) <= 15 then 'Low Frequency'
			else 'High Frequency'
		end as customer_types,
		count(distinct order_id) total_orders,
		SUM(quantity) total_qty,
		SUM(revenue) total_sales,
		SUM(profit) total_profit
	from sales
	group by customer_id
)
select
customer_types,
	COUNT(*) total_customers,
	sum(total_orders) num_order,
	sum(total_qty) total_qty,
	sum(total_sales) total_sales,
	sum(total_profit) total_profits,
	COUNT(*)*100.0 / sum(COUNT(*)) over() customer_pct,
	sum(total_profit) *100.0/ sum(sum(total_profit)) over() profit_contribution_pct
from customer_type
group by customer_types;

--============================================================================================
--============================================================================================
-- INSIGHT: 84.5% of customers are 'High Frequency' (over 15 orders).
-- BUSINESS IMPACT: This group drives ~90% of total profit. 
-- STRATEGY: Focus marketing budget on retaining this 84.5% to protect the bottom line.
--============================================================================================
--============================================================================================
