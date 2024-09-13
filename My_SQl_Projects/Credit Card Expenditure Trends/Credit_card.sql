-- Top 5 Cities with Highest Spend and Their Percentage Contribution
-- Highest Spend Month and Amount for Each Card Type
-- Transaction Details for Each Card Type When Cumulative Spend Reaches 1,000,000
-- City with Lowest Percentage Spend for Gold Card Type
-- City with Highest and Lowest Expense Type and Their Contribution
-- Percentage Contribution of Female Spends for Each Expense Type
-- Card Type and Expense Type with Maximum Growth in January 2014
-- City with Highest Spend-to-Transaction Ratio During Weekends
-- City That Took the Least Number of Days to Reach 500 Transactions After the First Transaction
-- Total Spend by Each Card and Their Contribution to Total Spend )

-- Create and Use Database
CREATE DATABASE Credit_card;
USE Credit_card;

-- Drop Table if Exists and Create New Table
DROP TABLE IF EXISTS credit_card;
CREATE TABLE Credit_card (
    `index` INT,
    city VARCHAR(100),
    date_ DATE,
    Card_type VARCHAR(20),
    Exp_type VARCHAR(50),
    Gender CHAR(1),
    Amount INT
);

-- Load Data into Table
LOAD DATA LOCAL INFILE '/Users/darshanpatel/Desktop/Webanalytics/credit_card.csv'
INTO TABLE credit_card
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Select All Records
SELECT * FROM Credit_card;

-- Check for Null Values
SELECT 
    SUM(CASE WHEN `index` IS NULL THEN 1 ELSE 0 END) AS index_null_value,
    SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS city_null_value,
    SUM(CASE WHEN date_ IS NULL THEN 1 ELSE 0 END) AS date_null_value,
    SUM(CASE WHEN Card_type IS NULL THEN 1 ELSE 0 END) AS card_type_null_value,
    SUM(CASE WHEN Exp_type IS NULL THEN 1 ELSE 0 END) AS exp_type_null_value,
    SUM(CASE WHEN Gender IS NULL THEN 1 ELSE 0 END) AS gender_null_value,
    SUM(CASE WHEN Amount IS NULL THEN 1 ELSE 0 END) AS amount_null_value
FROM credit_card;

-- Top 5 Cities with Highest Spend and Percentage Contribution
WITH city AS (
    SELECT 
        city,
        SUM(amount) AS City_total_amount
    FROM 
        credit_card
    GROUP BY 
        city
    ORDER BY 
        City_total_amount DESC
    LIMIT 5
),
total_amount AS (
    SELECT 
        SUM(amount) AS Total_amount
    FROM 
        Credit_card
)
SELECT 
    c.city,
    c.City_total_amount,
    t.Total_amount,
    ROUND(c.City_total_amount / t.Total_amount * 100, 2) AS Per_contribution
FROM 
    city c
JOIN 
    total_amount t ON 1 = 1
GROUP BY 
    c.city, t.Total_amount
ORDER BY 
    c.City_total_amount DESC;

-- Highest Spend Month and Amount for Each Card Type
WITH max_spend_month AS (
    SELECT 
        MONTH(date_) AS month_,
        YEAR(date_) AS year_,
        MAX(amount) AS total
    FROM 
        credit_card
    GROUP BY 
        month_, year_
    ORDER BY 
        total DESC
    LIMIT 1
)
SELECT 
    c.Card_type,
    m.month_ AS month_max,
    m.year_ AS year_max,
    SUM(c.amount) AS total_spend
FROM 
    credit_card c
JOIN 
    max_spend_month m ON MONTH(c.date_) = m.month_ AND YEAR(c.date_) = m.year_
GROUP BY 
    c.Card_type, m.month_, m.year_
ORDER BY 
    total_spend DESC;

-- Transaction Details for Each Card Type When Cumulative Spend Reaches 1,000,000
SELECT * 
FROM (
    SELECT *,
        DENSE_RANK() OVER (PARTITION BY card_type ORDER BY cumulative_sum) AS rank_
    FROM (
        SELECT *, 
            SUM(amount) OVER (PARTITION BY card_type ORDER BY date_, amount) AS cumulative_sum
        FROM credit_card
    ) AS K
    WHERE cumulative_sum >= 1000000
) AS m
WHERE rank_ = 1;

-- City with Lowest Percentage Spend for Gold Card Type
WITH gold_total_per_city AS (
    SELECT 
        city,  
        card_type,  
        SUM(amount) AS total_spend_gold 
    FROM 
        credit_card 
    WHERE 
        card_type = 'gold'  
    GROUP BY 
        city, card_type
),
total_gold_spend AS (
    SELECT 
        card_type,  
        SUM(amount) AS total_gold  
    FROM 
        credit_card   
    WHERE 
        card_type = 'gold'  
    GROUP BY 
        card_type
) 
SELECT   
    g.city,     
    g.card_type,  
    ROUND(SUM(g.total_spend_gold / t.total_gold * 100), 2) AS percentage_spent_gold 
FROM 
    gold_total_per_city g   
JOIN 
    total_gold_spend t ON g.card_type = t.card_type 
GROUP BY 
    g.card_type, g.city 
ORDER BY 
    percentage_spent_gold ASC
LIMIT 1;

-- City with Highest and Lowest Expense Type and Their Contribution
WITH T1 AS (
    SELECT 
        city,
        exp_type,
        SUM(amount) AS spent_amount
    FROM 
        Credit_card
    GROUP BY 
        city, exp_type
),
T2 AS (
    SELECT 
        city,
        MAX(spent_amount) AS highest_exp_amount,
        MIN(spent_amount) AS lowest_exp_amount
    FROM 
        T1
    GROUP BY 
        city
),
T3 AS (
    SELECT 
        city,
        SUM(amount) AS Total_city_spend
    FROM 
        Credit_card
    GROUP BY 
        city
)
SELECT
    T4.city,
    T4.Total_exp_type,
    T4.Highest_exp_type,
    T4.Lowest_exp_type,
    T4.Highest_exp_amount,
    T4.Lowest_exp_amount,
    ROUND(T4.Highest_exp_amount / T3.Total_city_spend * 100, 0) AS Highest_expense_per_of_citytotal,
    ROUND(T4.Lowest_exp_amount / T3.Total_city_spend * 100, 0) AS Lowest_expense_per_of_citytotal
FROM (
    SELECT
        T1.city,
        COUNT(DISTINCT T1.exp_type) AS Total_exp_type,
        MAX(CASE WHEN T2.highest_exp_amount = T1.spent_amount THEN T1.exp_type END) AS Highest_exp_type,
        MAX(CASE WHEN T2.lowest_exp_amount = T1.spent_amount THEN T1.exp_type END) AS Lowest_exp_type,
        MAX(CASE WHEN T2.highest_exp_amount = T1.spent_amount THEN T1.spent_amount END) AS Highest_exp_amount,
        MAX(CASE WHEN T2.lowest_exp_amount = T1.spent_amount THEN T1.spent_amount END) AS Lowest_exp_amount
    FROM    
        T1
    INNER JOIN 
        T2 ON T1.city = T2.city
    GROUP BY 
        T1.city
) AS T4
INNER JOIN 
    T3 ON T3.city = T4.city
ORDER BY 
    T4.Total_exp_type DESC,
    Highest_expense_per_of_citytotal DESC;

-- Percentage Contribution of Female Spends for Each Expense Type
WITH Total_female_spent AS (
    SELECT
        Exp_type,
        Gender,
        SUM(Amount) AS Total_Female_spent
    FROM
        credit_card
    WHERE 
        Gender = 'F'
    GROUP BY 
        Exp_type
),
total_exp_type_spent AS (
    SELECT
        Exp_type,
        SUM(Amount) AS Total_spent
    FROM
        credit_card
    GROUP BY 
        Exp_type
)
SELECT
    F.Gender,
    F.Exp_type,
    ROUND(SUM(F.Total_Female_spent / T.Total_spent * 100), 0) AS Total_Contribution 
FROM 
    Total_female_spent F
INNER JOIN 
    total_exp_type_spent T ON F.Exp_type = T.Exp_type
GROUP BY
    F.Exp_type, F.Gender
ORDER BY 
    Total_Contribution DESC;

-- Card Type and Expense Type with Maximum Growth in January 2014
WITH T1 AS (
    SELECT 
        Card_Type,
        Exp_Type,
        MONTH(date_) AS Month_,
        YEAR(date_) AS Year_,
        SUM(Amount) AS total_amount
    FROM 
        credit_card
    GROUP BY 
        Card_Type, Exp_Type, MONTH(date_), YEAR(date_)
),
T2 AS (
    SELECT
        Card_Type,
        Exp_Type,
        Month_,
        Year_,
        total_amount,
        LAG(total_amount, 1) OVER (PARTITION BY Card_Type, Exp_Type ORDER BY Year_, Month_) AS Previous_month_total
    FROM 
        T1
)
SELECT 
    G.Card_Type, 
    G.Exp_Type, 
    G.Month_, 
    G.Year_, 
    G.total_amount, 
    G.Previous_month_total,
    ROUND(SUM((G.total_amount - G.Previous_month_total) / COALESCE(G.Previous_month_total, 1)) * 100, 0) AS Growth_Percentage
FROM (
    SELECT 
        T2.Card_Type, 
        T2.Exp_Type, 
        T2.Month_, 
        T2.Year_, 
        T2.total_amount, 
        T2.Previous_month_total
    FROM T2
    WHERE 
        T2.Month_ = 1 
        AND T2.Year_ = 2014
) AS G
GROUP BY 
    G.Card_Type, G.Exp_Type, G.Month_, G.Year_, G.total_amount, G.Previous_month_total
ORDER BY 
    Growth_Percentage DESC 
LIMIT 1;

-- City with Highest Spend-to-Transaction Ratio During Weekends
SELECT 
    City, 
    SUM(Amount) / COUNT(*) AS Spend_to_Transactions_Ratio
FROM 
    Credit_card
WHERE 
    DAYOFWEEK(date_) IN (7, 1)
GROUP BY 
    City
ORDER BY 
    Spend_to_Transactions_Ratio DESC
LIMIT 1;

-- City That Took the Least Number of Days to Reach Its 500th Transaction After the First Transaction
WITH Rank_transaction AS (
    SELECT 
        City,
        date_,
        ROW_NUMBER() OVER (PARTITION BY City ORDER BY date_) AS Rank_
    FROM 
        Credit_card
    GROUP BY 
        City, date_
),
First_transaction AS (
    SELECT 
        City,
        MAX(CASE WHEN Rank_ = 1 THEN date_ END) AS First_transaction_date,
        MAX(CASE WHEN Rank_ = 500 THEN date_ END) AS last_transaction_date,
        COUNT(*) AS Total_Transactions
    FROM 
        Rank_transaction
    GROUP BY 
        City
    HAVING 
        Total_Transactions >= 500
)
SELECT 
    City,
    DATEDIFF(last_transaction_date, First_transaction_date) AS Days_TO_500_Transactions 
FROM 
    First_transaction
GROUP BY 
    City
ORDER BY 
    Days_TO_500_Transactions ASC
LIMIT 1;

-- Total Spend by Each Card Type and Their Respective Contribution to Total
WITH total_spend AS (
    SELECT
        SUM(Amount) AS total_amount
    FROM 
        Credit_card
),
Card_type AS (
    SELECT 
        card_type,
        SUM(Amount) AS Total_spend_card_type
    FROM 
        Credit_card
    GROUP BY 
        card_type
)
SELECT 
    c.Card_type,
    c.Total_spend_card_type,
    t.total_amount,
    (c.Total_spend_card_type / t.total_amount * 100) AS Per_contributed
FROM 
    total_spend t
INNER JOIN 
    Card_type c ON 1=1
ORDER BY 
    Per_contributed;
