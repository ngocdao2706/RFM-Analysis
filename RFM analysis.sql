/* FRM ANALYSIS*/
WITH rfm AS
(
	SELECT fi.CustomerKey
		, CONCAT_WS(' ', c.FirstName, c.MiddleName, c.LastName) AS CustomerName
		, MAX(OrderDate) AS RecentOrder
		, DATEDIFF(MONTH, MIN(CONVERT(CHAR(10), fi.OrderDate, 120)), '2015-01-01')  AS Monthsfrom1stpur
		, COUNT(DISTINCT(fi.SalesOrderNumber)) AS TotalOrder
		, DATEDIFF(YEAR, MIN(CONVERT(CHAR(10), fi.OrderDate, 120)), '2015-01-01') AS Yearsfrom1spur
		, COUNT(DISTINCT(fi.SalesOrderNumber))
			/CAST(DATEDIFF(YEAR, MIN(CONVERT(CHAR(10), fi.OrderDate, 120)), '2015-01-01') AS float)   AS NoPurchasePerYear
		,  CAST(SUM(SalesAmount)
			/ DATEDIFF(YEAR, MIN(CONVERT(CHAR(10), fi.OrderDate, 120)), '2015-01-01') AS float)  AS AmountPerYear
		, SUM(SalesAmount) - SUM(fi.ProductStandardCost) AS TotalProfit
	FROM FactInternetSales AS fi
		LEFT JOIN DimCustomer AS c
			ON fi.CustomerKey = c.CustomerKey
	GROUP BY fi.CustomerKey
		, CONCAT_WS(' ', FirstName, MiddleName, LastName)
), percentrank AS
(
	SELECT *
		, PERCENT_RANK () OVER (ORDER BY AmountPerYear DESC) AS AmountPerYear_rank
		, PERCENT_RANK () OVER (ORDER BY TotalProfit DESC) AS TotalProfit_rank
	FROM rfm
), segment AS 
(
	SELECT CustomerKey
		, CASE 
			WHEN YEAR(RecentOrder) = 2014 THEN 1
			ELSE 0
			END AS TopActive
		, CASE
			WHEN AmountPerYear_rank BETWEEN 0 AND 0.2 THEN 2
			ELSE 0
			END AS TopYear
		, CASE
			WHEN TotalProfit_rank BETWEEN 0 AND 0.2 THEN 2
			ELSE 0
			END AS TopProfit
		, CASE 
			WHEN NoPurchasePerYear > 1 THEN 1
			ELSE 0
			END AS TopPur
	FROM percentrank
), ScoreCustomer AS
(
SELECT CustomerKey
		, Score
		, SegmentedCustomer
FROM segment
		UNPIVOT(
		Score FOR SegmentedCustomer IN(TopActive, TopYear, TopProfit, TopPur)
		) AS u
), CustomerFinalScore AS
(
SELECT CustomerKey
	, SUM(Score) AS TotalScore
FROM ScoreCustomer
GROUP BY CustomerKey
), FinalCustomerSegment AS
(
SELECT CustomerKey
	, CASE 
		WHEN TotalScore >=5 THEN 'Diamond'
		WHEN TotalScore = 4 THEN 'Gold'
		WHEN TotalScore = 3 THEN 'Silver'
		WHEN TotalScore < 3 THEN 'Normal'
		END AS CustomerSegement
FROM CustomerFinalScore
)
SELECT rfm.CustomerKey
	, rfm.CustomerName
	, rfm.Monthsfrom1stpur AS MonthFrom1stPurchase
	, rfm.NoPurchasePerYear
	, rfm.AmountPerYear
	, rfm.TotalProfit
	, fcs.CustomerSegement
FROM rfm 
	LEFT JOIN FinalCustomerSegment AS fcs
		ON rfm.CustomerKey = fcs.CustomerKey
ORDER BY CustomerKey
	



	

