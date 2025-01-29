CREATE DATABASE INSURANCE;
USE INSURANCE;

#KPI 1 - Number of Invoice by Account Executive
SELECT `Account Executive`,
       SUM(CASE WHEN income_class = "Cross Sell" THEN 1 ELSE 0 END) AS Cross_Sell_Count,
       SUM(CASE WHEN income_class = "New" THEN 1 ELSE 0 END) AS New_Count,
       SUM(CASE WHEN income_class = "Renewal" THEN 1 ELSE 0 END) AS Renewal_Count,
       SUM(CASE WHEN income_class = "" THEN 1 ELSE 0 END) AS NULL_Invoice_count,
       COUNT(invoice_number) as Invoice_count
FROM invoice
GROUP BY `Account Executive`
ORDER BY Invoice_count desc;

SET SQL_SAFE_UPDATES = 0;
UPDATE meeting
SET meeting_date = STR_TO_DATE(meeting_date, '%d-%m-%Y');

ALTER TABLE meeting
MODIFY COLUMN meeting_date DATE;

# KPI 2 - Yearly Meeting Count
SELECT YEAR(meeting_date) as Meeting_Year, count(meeting_date)  as Meeting_count
FROM meeting
GROUP BY Meeting_Year;


#KPI 4 - Stage Funnel by Revenue
SELECT stage, SUM(revenue_amount) Revenue_amt
FROM opportunity
GROUP BY stage
ORDER BY Revenue_amt desc;

#KPI 5 -Number of Meetings by Account Executive
SELECT `Account Executive`, COUNT(*) as Meeting_count
from meeting
GROUP BY `Account Executive`
ORDER BY Meeting_count desc;

#KPI 6 - TOP 5 OPPORTUNITY BY REVENUE
SELECT opportunity_name , SUM(revenue_amount) as Revenue_amt
FROM opportunity
GROUP BY opportunity_name 
ORDER BY Revenue_amt desc
LIMIT 5;

# Opportunity - Product distribution
SELECT product_group,
COUNT(`Account Executive`) AS oppty_count,
CONCAT(FORMAT((COUNT(`Account Executive`)* 100.0/SUM(COUNT(`Account Executive`)) OVER()),2),'%')
AS Total_Percent FROM opportunity
GROUP BY product_group;

#Procedure

DELIMITER //
CREATE PROCEDURE `Data_by_IncomeClass` (IN IncomeClass varchar(20))
BEGIN
DECLARE Budget_val double;
## Target, Invoice, Achieved for Cross Sell, New, Renewal
SET @Cross_Sell_Target = (SELECT SUM(`Cross sell bugdet`) FROM individual_budgets);
SET @New_Target = (SELECT SUM(`New Budget`) FROM individual_budgets);
SET @Renewal_Target = (SELECT SUM(`Renewal Budget`) FROM individual_budgets);

SET @Invoice_val = (SELECT SUM(Amount) FROM invoice WHERE income_class = IncomeClass);
SET @Achieved_val = ((SELECT SUM(Amount) FROM brokerage WHERE income_class = IncomeClass) + 
                                   (SELECT SUM(Amount) FROM fees WHERE income_class=IncomeClass));

IF IncomeClass="Cross Sell" THEN SET Budget_val = @Cross_Sell_Target;
 ELSEIF IncomeClass = "New" THEN SET Budget_val = @New_Target;
 ELSEIF IncomeClass = "Renewal" THEN SET Budget_val = @Renewal_Target;
 ELSE SET Budget_val = 0;
END IF;

## Percentage of Placed Achievement for Cross Sell, New, and Renewal
SET @Placed_achvment = (SELECT CONCAT(FORMAT((@Achieved_val / Budget_val)*100,2), '%'));

## Percentage of Invoice Achievement for Cross Sell, New, and Renewal
SET @Invoice_achvment = (SELECT CONCAT(FORMAT((@Invoice_val / Budget_val)*100,2), '%'));
SELECT IncomeClass, Format (Budget_val,0) as Target, Format(@Invoice_val,0) as Invoice,
        Format (@Achieved_val,2) as Achieved, @Placed_achvment as Placed_Achievement_Percentage,
        @Invoice_achvment as Invoice_Achievement_Percentage;

END//

# KPI 3 - Target, Invoice, Achieved, Placed_Achvmt_percent
# Invoice_Achvmt_percent by Income_Class 
# (Cross Sell, New, Renewal)

Delimiter ; //
CALL Data_by_IncomeClass('Cross Sell');

Delimiter ; // 
CALL Data_by_IncomeClass('New');

Delimiter ; // 
CALL Data_by_IncomeClass('Renewal');