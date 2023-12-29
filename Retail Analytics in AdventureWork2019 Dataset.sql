-- Tính SUM (OrderQuantity, TotalProductCost, SalesAmount, TaxAmt, Freight) từ 2 bảng FactResellerSales và FactInternetSales
SELECT 
    a.ProductKey,
    DP.EnglishProductName,
    SUM(a.OrderQuantity) AS Order_Quantity,
    SUM(a.TotalProductCost) AS Total_Product_Cost,
    SUM(a.SalesAmount) AS Total_Sales_Amount,
    SUM(TaxAmt) AS Total_Tax_Amount,
    SUM(Freight) AS Total_Freight
FROM
(SELECT 
    ProductKey,
    PromotionKey,
    CurrencyKey,
    SalesTerritoryKey,
    OrderQuantity,
    UnitPrice,
    TotalProductCost,
    SalesAmount,
    TaxAmt,
    Freight
FROM FactResellerSales
UNION ALL 
SELECT 
    ProductKey,
    PromotionKey,
    CurrencyKey,
    SalesTerritoryKey,
    OrderQuantity,
    UnitPrice,
    TotalProductCost,
    SalesAmount,
    TaxAmt,
    Freight
FROM FactInternetSales) AS a   
LEFT JOIN DimProduct AS DP ON a.ProductKey = DP.ProductKey
GROUP BY 
    a.ProductKey,
    DP.EnglishProductName;

-- Kiểm tra xem các nhân viên ở các khu vực Reseller có hoàn thành được sales Quota hay ko?
SELECT 
    c.SalesTerritoryRegion,
    a.*,
    b.Amount_Quota,
CASE 
    WHEN a.Amount_Sale >= b.Amount_Quota THEN 'Complete'
	WHEN a.Amount_Sale <= b.Amount_Quota THEN 'Not completed' 
	ELSE 'No rating'
END AS 'EValue'
FROM (
SELECT 
    FRS.SalesTerritoryKey, 
    Year(FRS.OrderDate) AS YearOfDate,
    DATEPART(QUARTER, FRS.OrderDate) AS QuaterOfDate,
    SUM(FRS.OrderQuantity) AS Amount_Sale
FROM FactResellerSales AS FRS
GROUP BY 
    FRS.SalesTerritoryKey,
    Year(FRS.OrderDate),
    DATEPART(QUARTER, FRS.OrderDate)) AS a
LEFT JOIN
(SELECT 
    DE.SalesTerritoryKey,
    FSQ.CalendarYear, 
    FSQ.CalendarQuarter,
    SUM(FSQ.SalesAmountQuota) AS Amount_Quota 
FROM FactSalesQuota AS FSQ
LEFT JOIN DimEmployee AS DE ON FSQ.EmployeeKey = DE.EmployeeKey
GROUP BY 
    DE.SalesTerritoryKey,
    FSQ.CalendarYear,
    FSQ.CalendarQuarter) AS b 
ON a.SalesTerritoryKey = b.SalesTerritoryKey
AND a.YearOfDate = b.CalendarYear
AND a.QuaterOfDate = b.CalendarQuarter
LEFT JOIN DimSalesTerritory AS c ON a.SalesTerritoryKey = c.SalesTerritoryKey;


-- Xuất các bảng để làm báo cáo doanh thu kênh bán hàng online
SELECT 
    FIS.ProductKey AS Product_Key,
    FIS.CustomerKey AS Customer_Key,
    FIS.CurrencyKey AS Currency_Key,
    DP.EnglishProductName AS Product_name,
    DPS.EnglishProductSubcategoryName AS Product_Subcategor_Name,
    DPC.EnglishProductCategoryName AS Product_Category_Name,
    CONCAT_WS(' ', FirstName, MiddleName, LastName) AS Customer_Full_Name,
    DST.SalesTerritoryKey AS Territory_Country,
    DST.SalesTerritoryRegion AS Territory_Region,
    DCR.CurrencyName AS Currency_Name,
    FCR.EndOfDayRate AS Currency_Rate,
    FIS.OrderQuantity AS Order_Quantity,
    ROUND(FCR.EndOfDayRate * FIS.UnitPrice,2) AS Unit_Price,
    ROUND(FCR.EndOfDayRate * FIS.TotalProductCost,2) AS Total_Produt_Cost,
    ROUND(FCR.EndOfDayRate * FIS.SalesAmount,2) AS Sales_Amount,
    ROUND(FCR.EndOfDayRate * FIS.TaxAmt,2) AS TaxAmt, 
    ROUND(FCR.EndOfDayRate * FIS.Freight,2) AS Freight,
    FIS.OrderDate,
    YEAR(OrderDate) AS Year_Of_Date,
    QuarterOfDate = DATEPART(QUARTER,OrderDate),
    MonthOfDate =  Month(OrderDate)
FROM FactInternetSales AS FIS 
LEFT JOIN DimProduct AS DP ON FIS.ProductKey = DP.ProductKey
LEFT JOIN DimProductSubcategory AS DPS ON DP.ProductSubcategoryKey = DPS.ProductSubcategoryKey
LEFT JOIN DimProductCategory AS DPC ON DPS.ProductCategoryKey = DPC.ProductCategoryKey
LEFT JOIN DimCustomer AS DC ON FIS.CustomerKey = DC.CustomerKey
LEFT JOIN DimSalesTerritory AS DST ON FIS.SalesTerritoryKey = DST.SalesTerritoryKey
LEFT JOIN DimCurrency AS DCR ON FIS.CurrencyKey = DCR.CurrencyKey
LEFT JOIN FactCurrencyRate AS FCR ON FIS.DueDateKey = FCR.DateKey AND FIS.CurrencyKey = FCR.CurrencyKey; 