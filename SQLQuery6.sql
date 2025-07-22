use StoreDB
/*
1. Customer Spending Analysis#
Write a query that uses variables to find the total amount spent by customer ID 1.
Display a message showing whether they are a VIP customer (spent > $5000) or regular customer.
*/
declare @total_spent decimal
select @total_spent= sum(list_price*quantity) from sales.customers c join sales.orders o on c.customer_id=o.customer_id
join sales.order_items oi on o.order_id = oi.order_id
where c.customer_id = 1
select @total_spent , iif(@total_spent>5000,'Vip','regular')

/*
2. Product Price Threshold Report#
Create a query using variables to count how many products cost more than $1500. Store the threshold price in a variable
and display both the threshold and count in a formatted message.
*/

declare @threshold money = 1500
select  @threshold as threshold, count(p.product_id) No_Of_Product 
from production.products p join sales.order_items oi on p.product_id = oi.product_id
having sum(oi.list_price*oi.quantity) > @threshold

/*
3. Staff Performance Calculator#
Write a query that calculates the total sales for staff member ID 2 in the year 2017. Use variables to store the staff ID, year, and calculated total.
Display the results with appropriate labels.
*/

declare @staff_id int =2 , @Year smallint = 2017 
select @staff_id, @Year, sum(oi.list_price*oi.quantity*(1-discount)) 
from sales.staffs s join sales.orders o on s.staff_id = o.staff_id 
join sales.order_items oi on o.order_id = oi.order_id 
where s.staff_id = @staff_id and YEAR(order_date) = @Year 

/*
4. Global Variables Information#
Create a query that displays the current server name, SQL Server version,
and the number of rows affected by the last statement. Use appropriate global variables.
*/
select @@SERVERNAME , @@VERSION , @@ROWCOUNT 

/*
5.Write a query that checks the inventory level for product ID 1 in store ID 1. 
Use IF statements to display different messages based on stock levels:#
If quantity > 20: Well stocked
If quantity 10-20: Moderate stock
If quantity < 10: Low stock - reorder needed
*/

declare @product_id int  = 1;
declare @store_id   int  = 1;
declare @quantity   int;

select @quantity = ISNULL(st.quantity, 0)
FROM   production.stocks st
WHERE  st.product_id = @product_id
  AND  st.store_id   = @store_id;
IF (@quantity > 20)
    PRINT 'Well stocked';
ELSE IF (@quantity BETWEEN 10 AND 20)
    PRINT 'Moderate stock';
ELSE
    PRINT 'Low stock - reorder needed';

/*
6.Create a WHILE loop that updates low-stock items (quantity < 5) in batches of 3 products at a time. 
Add 10 units to each product and display progress messages after each batch.
*/

declare @rowsAffected int =1;
while @rowsAffected > 0
begin
 update top(3) production.stocks 
 set quantity += 10
 where quantity < 5;

 set @rowsAffected = @@ROWCOUNT

 if @rowsAffected > 0
 print concat(cast(@rowsAffected as varchar(10)) ,' ', 'products updated');
 end

 /*
 7. Product Price Categorization#
Write a query that categorizes all products using CASE WHEN based on their list price:

Under $300: Budget
$300-$800: Mid-Range
$801-$2000: Premium
Over $2000: Luxury
 */

 select 
 case 
 when list_price < 300 then 'Budget'
 when list_price between 300 and 800 then 'Mid-Range'
 when list_price between 801 and 2000 then 'Premium'
 when list_price > 2000 then 'Luxury'
 end AS price_category
 from production.products

 /*
 8. Customer Order Validation#
Create a query that checks if customer ID 5 exists in the database.
If they exist, show their order count. If not, display an appropriate message.
 */
 declare @cust_id int 
 select @cust_id = customer_id from sales.customers where customer_id =5
 if @cust_id is not null 
  select COUNT(*) from sales.orders where customer_id = @cust_id
  else 
  select 'No Orders With customer ID 5 ' as message
/*
9. Shipping Cost Calculator Function#
Create a scalar function named CalculateShipping that takes an order total as input and returns shipping cost:

Orders over $100: Free shipping ($0)
Orders $50-$99: Reduced shipping ($5.99)
Orders under $50: Standard shipping ($12.99)
*/

create function CalculateShipping (@order_total decimal)
returns  decimal 
as
begin
    declare @shipping_cost decimal 
    if @order_total > 100  
      set  @shipping_cost = 0
    else if @order_total >= 50 AND @order_total < 100
    set @shipping_cost = 5.99
    else 
   set @shipping_cost = 12.99
   return @shipping_cost
end;

select dbo.CalculateShipping(40)

/*
10. Product Category Function#
Create an inline table-valued function named GetProductsByPriceRange that accepts
minimum and maximum price parameters and returns all products within that price rangewith their brand and category information.
*/
create function GetProductsByPriceRange(@min_price int ,@max_price int)
returns table 
as 
  return(
  select p.product_id,p.product_name,p.list_price,b.brand_name,c.category_name from production.products p join production.brands b on p.brand_id = b.brand_id 
  join production.categories c on p.category_id = c.category_id 
  where list_price between @min_price and @max_price 
  );
  select * from dbo.GetProductsByPriceRange(50,100)

  /*
  11. Customer Sales Summary Function#
Create a multi-statement function named GetCustomerYearlySummary that takes a customer ID and 
returns a table with yearly sales data including total orders,total spent, and average order value for each year.
  */
  create function GetCustomerYearlySummary (@customer_id int) 
  returns @summary table (order_year int , order_count int,total_amount decimal(10,2),aveforvalue decimal(10,2))
  as 
  begin 
  insert into @summary
  select YEAR(order_date),count(o.order_id),sum(oi.list_price*oi.quantity*(1-discount)),avg(oi.list_price*oi.quantity*(1-discount)) 
  from sales.orders o join sales.order_items oi 
  on o.order_id = oi.order_id
  where customer_id = @customer_id
  group by YEAR(order_date) 
  return ;
  end
  select * from dbo.GetCustomerYearlySummary(6)

 /*
 12. Discount Calculation Function#
Write a scalar function named CalculateBulkDiscount that determines discount percentage based on quantity:

1-2 items: 0% discount
3-5 items: 5% discount
6-9 items: 10% discount
10+ items: 15% discount
 */

 create function CalculateBulkDiscount (@quantity int) 
 returns decimal 
 as 
 begin 
 declare @percentage decimal 
 if @quantity = 1 or @quantity = 2 
 set @percentage = 0
 else if @quantity in (3,4,5) 
 set @percentage = 5 
 else if @quantity in (6,7,8,9) 
 set @percentage = 10 
 else 
 set @percentage = 15 

 return @percentage
 end;

 select dbo.CalculateBulkDiscount(5)

 /*
 13. Customer Order History Procedure#
Create a stored procedure named sp_GetCustomerOrderHistory
that accepts a customer ID and optional start/end dates. Return the customer's order history with order totals calculated.
 */

 create procedure sp_GetCustomerOrderHistorys
 @customer_id int ,
 @start_date date = null,
 @end_date date =  null
    as 
    begin
    select order_date,sum(oi.list_price*oi.quantity*(1-quantity)) --modified
    from sales.orders o join sales.order_items oi on o.order_id = oi.order_id 
    where customer_id = @customer_id 
     AND (@start_date IS NULL OR o.order_date >= @start_date)
        AND (@end_date IS NULL OR o.order_date <= @end_date)
    group by order_date
    end

    exec sp_GetCustomerOrderHistorys @customer_id = 1 , @start_date = '2023-01-01'
/*
14. Inventory Restock Procedure#
Write a stored procedure named sp_RestockProduct with input parameters for store ID, product ID,
and restock quantity. Include output parameters for old quantity, new quantity, and success status.
*/
create procedure sp_RestockProduct
@store_id int ,@product_id int ,@restock_qua int,
@oldqua int output ,@newqua int output ,@success bit output
as
begin 
    declare @current_qty int
    select @current_qty=quantity from production.stocks where store_id  =  @store_id and product_id  =@product_id
    if @current_qty is not null and @restock_qua > 0
    begin
    set @oldqua = @current_qty
    set @newqua = @current_qty + @restock_qua
    update production.stocks 
    set quantity = @newqua where store_id  =  @store_id and product_id  =@product_id
    set @success =1
    end
    else 
    begin
       SET @oldqua = 0
        SET @newqua = 0
        SET @success = 0
    end
end
    declare @old int , @new int , @status bit
exec sp_RestockProduct @store_id =1 ,@product_id =10,@restock_qua =20,
@oldqua = @old output , @newqua = @new output ,@success = @status output 

select @old as oldqua ,@new as newqua ,@status as success

/*
15. Order Processing Procedure#
Create a stored procedure named sp_ProcessNewOrder that handles complete order creation with proper transaction control and error handling.
Include parameters for customer ID, product ID, quantity, and store ID.
*/

create procedure sp_ProcessNewOrder 
@customer_id int , @product_id int , @quantity int ,@store_id int
as 
begin 
                 begin try 
         begin transaction
    declare @availqua int 
    select @availqua = quantity from production.stocks  where store_id = @store_id and product_id  =@product_id 
    if @availqua < @quantity 
    print ('insufficient stock')

    insert into sales.orders (customer_id,order_status,order_date,store_id)--modified
    values(@customer_id,1,GETDATE(),@store_id)

    declare @order_id int = scope_identity()
    insert into sales.order_items(order_id,item_id,product_id,list_price,discount)--modified
    values(@order_id,
    1,
    @product_id,
    (select list_price from production.products where product_id =@product_id),
    0)
    update production.stocks 
    set quantity =quantity-@quantity
     where store_id = @store_id and product_id  =@product_id
    commit transaction
    end try
    begin catch
    rollback transaction
    print error_message()
    end catch
end
exec sp_ProcessNewOrder @customer_id =1,@product_id =10,@quantity =2,@store_id=2;

/*
16. Dynamic Product Search Procedure#
Write a stored procedure named sp_SearchProducts that builds dynamic SQL based on optional parameters: 
product name search term, category ID, minimum price, maximum price, and sort column.
*/
create proc sp_SearchProducts @product_name varchar(50)='Nike Tech Fleece Hoodie - Gray',
@category_id int=3,
@min_price int=50,
@max_price int=150,
@sort_column varchar(5)
as 
begin
    select @product_name,@min_price,@max_price,@category_id 
    from production.products where product_name = @product_name and category_id = @category_id 
    order by list_price desc
end

select * from production.products

/*
17. Staff Bonus Calculation System#
Create a complete solution that calculates quarterly bonuses for all staff members.Use variables to store 
date ranges and bonus rates. Apply different bonus percentages based on sales performance tiers.
*/

create procedure sp_CalculateQuarterlyBonuses 
as 
begin
    declare @start_date date = '2025-01-01'
    declare @end_date date = '2025-03-31'

    declare @low_bouns_rate decimal(5,2) = 0.03
     declare @medium_bouns_rate decimal(5,2) = 0.05
      declare @high_bouns_rate decimal(5,2) = 0.10

      create table sales_performane(
      staff_id int,
      total_sales money,
      bouns money
      )
      insert into sales_performane 
      select s.staff_id,sum(oi.list_price*oi.quantity*(1-discount))as total_sales,
      case 
      when sum(oi.list_price*oi.quantity*(1-discount)) < 10000 
      then sum(oi.list_price*oi.quantity*(1-discount))*@low_bouns_rate
      when sum(oi.list_price*oi.quantity*(1-discount)) between 10000 and 50000
      then sum(oi.list_price*oi.quantity*(1-discount))*@medium_bouns_rate
      when sum(oi.list_price*oi.quantity*(1-discount)) > 50000 
      then sum(oi.list_price*oi.quantity*(1-discount))*@high_bouns_rate
      end as bouns
      from StoreDB.sales.orders o join StoreDB.sales.staffs s on s.staff_id = o.staff_id join
      StoreDB.sales.order_items oi on o.order_id = oi.order_id
      where order_date between @start_date and @end_date
      group by s.staff_id

      select * from sales_performane
end
exec sp_CalculateQuarterlyBonuses

/*
18. Smart Inventory Management#
Write a complex query with nested IF statements that manages inventory restocking. Check current stock levels
and apply different reorder quantities based on product categories and current stock levels.
*/

select p.product_name,c.category_name,s.quantity as currentStock,
case 
when c.category_name = 'Unisex Sneakers'  then 
    case 
    when s.quantity < 10 then 20
    else 0
    end
when c.category_name ='Belts' then 
case 
when s.quantity < 20 then 40
else 0
end
when s.quantity < 50 then 100
else 0
end as reorder_quantity
from StoreDB.production.stocks s join StoreDB.production.products p on s.product_id=p.product_id
join StoreDB.production.categories c on p.category_id = c.category_id


/*
19. Customer Loyalty Tier Assignment#
Create a comprehensive solution that assigns loyalty tiers to customers based on their total spending. 
Handle customers with no orders appropriately and use proper NULL checking.
*/
select c.customer_id, 
sum(oi.list_price*oi.quantity*(1-discount)) total_spending,
case 
when sum(oi.list_price*oi.quantity*(1-discount)) >= 10000 then 'Platinum'
when sum(oi.list_price*oi.quantity*(1-discount)) between 5000 and 10000 then 'Gold'
when sum(oi.list_price*oi.quantity*(1-discount)) between 1000 and 5000 then 'Silver'
 else 'Bronze' 
end as loyalty_spending ,
isnull(o.order_status,0)
from StoreDB.sales.customers c left join StoreDB.sales.orders o on c.customer_id = o.customer_id 
left join StoreDB.sales.order_items oi on o.order_id = oi.order_id  
group by c.customer_id,isnull(o.order_status,0)

/*
20. Product Lifecycle Management#
Write a stored procedure that handles product discontinuation including checking for pending orders,
optional product replacement in existing orders,clearing inventory, and providing detailed status messages.
*/
create procedure sp_manageOrders 