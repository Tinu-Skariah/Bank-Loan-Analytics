USE shafi;

SELECT * FROM `debit and credit banking_data`;

--- 1. no of Transaction Done by bank 
select count(*) as Transactions from `debit and credit banking_data`;

--- 2. no of bounus_ payments issued by bank
select count(*) as bounus_payments from `debit and credit banking_data` where Description='bonus payment';


--- 3. how many member used for online shoping
select count(*) as onlie_shoping from `debit and credit banking_data` where Description='online shopping';

--- 4. how many member refund from retailer
select count(*) as refund_from_retailer from `debit and credit banking_data` where Description='refund from retailer';

--- 5. how many members are used credit
select count(*) as credit from `debit and credit banking_data` where `Transaction Type`= 'credit';
alter table `debit and credit banking_data` Rename column `Bank Name` to bank;

--- 6. Total debit and credit amount bank wise
select bank,format(sum(case when `Transaction Type`='debit' then amount else 0 end)/1000000,2) as total_debit_M
,format(sum(case when `Transaction Type`='credit' then amount else 0 end)/1000000,2) as total_credit_M 
from `debit and credit banking_data`group by bank order by total_debit_M,total_credit_M desc;

--- 7. average transation amount by transation type --
select `Transaction Type`,concat('₹',format(avg(amount),2))as average_amount 
from `debit and credit banking_data` group by `Transaction Type`;

--- 8. using haveing caluse
--- name wise total debit amount less than 10000
select `Customer Name`,concat('₹', format(sum(amount),2))as total_debit from `debit and credit banking_data`
where `Transaction Type`='debit' group by `Customer Name` having sum(amount) <=10000;

--- 9. list transaction type less than 2 transactions---
select `Customer Name`,count(*) as trans_count from `debit and credit banking_data`group by `customer name` having count(*) <2;

--- 10. no of accounts with average credit amount less than 10000, and debit amount less than 10000,
select  `Customer id`, concat('₹',format(avg(amount),2)) as avg_credit,
concat('₹',format(avg(amount),2)) as avg_debit from `debit and credit banking_data`
group by `customer id` having avg(amount) < 10000;

---  11. most used transaction methods--
select `Transaction Method`,count(*) as count  from `debit and credit banking_data` 
group by `Transaction Method`order by count desc limit 3;

--- 12. top 10 customer transaction 
select `customer id` , `customer Name` ,`account number`,`transaction date` ,`transaction type`,Amount
from `bank_transactions` order by amount desc limit 10 ;

--- 13. branch wise average transaction
select branch, concat('₹',format(avg(amount),2)) as avg_amount from `debit and credit banking_data` group by branch order by avg_amount desc;

--- 14. Count of deposit and withdrawals
select `Transaction Type`, count(*) as count from `debit and credit banking_data`group by `Transaction Type`;

--- 15. Total transctions per day
select `Transaction Date`, count(*)  as total_transaction  from `debit and credit banking_data`group by `Transaction Date` order by total_transaction desc;	

---- 16 view by only customer,acoount,number,transction method;
create view customer as select `Customer Name` ,`account Number`,`Transaction Method`,balance from `debit and credit banking_data` ;
select*from customer;

---- 17 bank wise daily credit and debit summary
create view bank_daily_summarys as 
select bank,`transaction date`,
round(
sum(case when `transaction type`='credit' then amount else 0 end),2)as total_credit,
round(
sum(case when `transaction type`='debit' then amount else 0 end),2)as total_debit,
round(
sum(case when `transaction type`='credit' then amount else 0 end)-
sum(case when `transaction type`='debit' then amount else 0 end),2)as net_amount
from `debit and credit banking_data` group by bank,`transaction date`;
select*from bank_daily_summarys;

---- 18 bank wise daily credit and debit summary
create view avg_bank_daily_summarys as 
select bank,`transaction date`,
round(
avg(case when `transaction type`='credit' then amount else 0 end),2)as total_credit,
round(
avg(case when `transaction type`='debit' then amount else 0 end),2)as total_debit,
round(
avg(case when `transaction type`='credit' then amount else 0 end)-
avg(case when `transaction type`='debit' then amount else 0 end),2)as net_amount
from `debit and credit banking_data` group by bank,`transaction date`;
select*from avg_bank_daily_summarys;

---- 19 create index on customer name account number bank name
create index  customer_ds on `debit and credit banking_data`(`Customer Name`(40),bank(30));
show index from `debit and credit banking_data`;
explain Select * from `debit and credit banking_data` where `customer name`='justin warner';

--- 20 create index on bank and transaction date
create index `customer id` on `debit and credit banking_data`(bank(50),`transaction date`(40));
show index from`debit and credit banking_data`;
explain select *from `debit and credit banking_data`where bank='axis bank';

--- 21 create index on name  
create index idx_name on `debit and credit banking_data`(`customer Name`);
show index from `debit and credit banking_data`;
explain select * from  `debit and credit banking_data` where `customer Name`='justin Larson';

---- 22 create index on bank transaction type 
Create index Idx_transation_type on `debit and credit banking_data`(`transaction type`(80));
show index from `debit and credit banking_data`;
explain select *from `debit and credit banking_data`where `transaction type`='debit';


--- 23 stored procdure
---- bank wise loans isuue 
CREATE DEFINER=`root`@`localhost` PROCEDURE `total loans by bank`()
BEGIN
select bank, count(*) as total_loans 
from `debit and credit banking_data`group by bank;
END;
call shafi.`total loans by bank`();

---- 24 bank wise total amount
CREATE DEFINER=`root`@`localhost` PROCEDURE `bank total`(in P_bank varchar(50))
BEGIN
select bank,sum(amount)as total_amount 
from `debit and credit banking_data`
where bank=p_bank
group by bank;
End;
call shafi.`bank total`('axis bank');

--- 25 top n customers by total amount
CREATE DEFINER=`root`@`localhost` PROCEDURE `Top N customers`(in p_limit int)
BEGIN
select 
`customer id`,
sum(amount) as total_Amount 
from `debit and credit banking_data`
group by `customer id`
order by total_amount desc;
end;
call shafi.`Top N customers`(10);

-- 26 window function 
select bank,`customer id`,amount,rank() 
over
(partition by bank order by amount desc) 
as amount_rank from `debit and credit banking_data`;

-- 27 bank wise cumulative credit and debit 

select bank,`transaction type`,`transaction date`,amount,
row_number() over ( partition by bank order by `transaction type` asc)as row_num,
round(sum(case when `transaction type`= 'credit' then amount else 0 end)
over(partition by bank order by`transaction date`asc) ,2)as running_credit,
round(sum(case when `transaction type`='debit' then amount else 0 end)
over( partition by bank order by`transaction date`asc),2)as runnimg_debit
from
`debit and credit banking_data`order by bank ,`transaction Type`asc;
