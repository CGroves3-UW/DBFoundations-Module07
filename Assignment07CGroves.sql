--*************************************************************************--
-- Title: Assignment07 Creating Functions in a Database
-- Author: Clariecia Groves
-- Desc: This file contains a script that creates multiple functions based
-- on data within the the categories, products, employees, and inventories 
-- tables 
-- Change Log: When,Who,What
-- 2020-08-24,CGroves,Created File
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment07DB_CGroves')
	 Begin 
	  Alter Database [Assignment07DB_CGroves] set Single_user With Rollback Immediate;
	  Drop Database Assignment07DB_CGroves;
	 End
	Create Database Assignment07DB_CGroves;
End Try
Begin Catch
	Print Error_Number();
End Catch
Go

Use Assignment07DB_CGroves;

-- Create Tables (Module 01)-- 
Create Table Categories
([CategoryID] [int] IDENTITY(1,1) NOT NULL 
,[CategoryName] [nvarchar](100) NOT NULL
);
Go

Create Table Products
([ProductID] [int] IDENTITY(1,1) NOT NULL 
,[ProductName] [nvarchar](100) NOT NULL 
,[CategoryID] [int] NULL  
,[UnitPrice] [money] NOT NULL
);
Go

Create Table Employees -- New Table
([EmployeeID] [int] IDENTITY(1,1) NOT NULL 
,[EmployeeFirstName] [nvarchar](100) NOT NULL
,[EmployeeLastName] [nvarchar](100) NOT NULL 
,[ManagerID] [int] NULL  
);
Go

Create Table Inventories
([InventoryID] [int] IDENTITY(1,1) NOT NULL
,[InventoryDate] [Date] NOT NULL
,[EmployeeID] [int] NOT NULL
,[ProductID] [int] NOT NULL
,[ReorderLevel] int NOT NULL -- New Column 
,[Count] [int] NOT NULL
);
Go

-- Add Constraints (Module 02) -- 
Begin  -- Categories
	Alter Table Categories 
	 Add Constraint pkCategories 
	  Primary Key (CategoryId);

	Alter Table Categories 
	 Add Constraint ukCategories 
	  Unique (CategoryName);
End
Go 

Begin -- Products
	Alter Table Products 
	 Add Constraint pkProducts 
	  Primary Key (ProductId);

	Alter Table Products 
	 Add Constraint ukProducts 
	  Unique (ProductName);

	Alter Table Products 
	 Add Constraint fkProductsToCategories 
	  Foreign Key (CategoryId) References Categories(CategoryId);

	Alter Table Products 
	 Add Constraint ckProductUnitPriceZeroOrHigher 
	  Check (UnitPrice >= 0);
End
Go

Begin -- Employees
	Alter Table Employees
	 Add Constraint pkEmployees 
	  Primary Key (EmployeeId);

	Alter Table Employees 
	 Add Constraint fkEmployeesToEmployeesManager 
	  Foreign Key (ManagerId) References Employees(EmployeeId);
End
Go

Begin -- Inventories
	Alter Table Inventories 
	 Add Constraint pkInventories 
	  Primary Key (InventoryId);

	Alter Table Inventories
	 Add Constraint dfInventoryDate
	  Default GetDate() For InventoryDate;

	Alter Table Inventories
	 Add Constraint fkInventoriesToProducts
	  Foreign Key (ProductId) References Products(ProductId);

	Alter Table Inventories 
	 Add Constraint ckInventoryCountZeroOrHigher 
	  Check ([Count] >= 0);

	Alter Table Inventories
	 Add Constraint fkInventoriesToEmployees
	  Foreign Key (EmployeeId) References Employees(EmployeeId);
End 
Go

-- Adding Data (Module 04) -- 
Insert Into Categories 
(CategoryName)
Select CategoryName 
 From Northwind.dbo.Categories
 Order By CategoryID;
Go

Insert Into Products
(ProductName, CategoryID, UnitPrice)
Select ProductName,CategoryID, UnitPrice 
 From Northwind.dbo.Products
  Order By ProductID;
Go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
Go

Insert Into Inventories
(InventoryDate, EmployeeID, ProductID, ReorderLevel, [Count])
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, ReorderLevel, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Union
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, ReorderLevel, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Union
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, ReorderLevel, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Order By 1, 2
Go

-- Adding Views (Module 06) -- 
Create View vCategories With SchemaBinding
 AS
  Select CategoryID, CategoryName From dbo.Categories;
Go

Create View vProducts With SchemaBinding
 AS
  Select ProductID, ProductName, CategoryID, UnitPrice From dbo.Products;
Go

Create View vEmployees With SchemaBinding
 AS
  Select EmployeeID, EmployeeFirstName, EmployeeLastName, ManagerID From dbo.Employees;
Go

Create View vInventories With SchemaBinding 
 AS
  Select InventoryID, InventoryDate, EmployeeID, ProductID, ReorderLevel, [Count] From dbo.Inventories;
Go

-- Show the Current data in the Categories, Products, and Inventories Tables
Select * From vCategories;
Go
Select * From vProducts;
Go
Select * From vEmployees;
Go
Select * From vInventories;
Go

/********************************* Questions and Answers *********************************/
--NOTES------------------------------------------------------------------------------------ 
-- 1) You must use the BASIC views for each table.
-- 2) Remember that Inventory Counts are Randomly Generated. So, your counts may not match mine
-- 3) To make sure the Dates are sorted correctly, you can use Functions in the Order By clause!
------------------------------------------------------------------------------------------'

-- Question 1 (5 pts): What function can you use to show a list of Product names, 
-- and the price of each product, with the price formatted as US dollars?
-- Order the result by the product!

Create Function fProductsAndPrice() 
 Returns Table 
 As
   Return(
    Select Top 1000000000
	 p.ProductName, 
	 UnitPrice = Format(p.UnitPrice, 'C', 'en-US')  
	 From vProducts as p 
	Order By 1
	);
Go

-- Check that it works
Select * From dbo.fProductsAndPrice(); 

-- Question 2 (10 pts): What function can you use to show a list of Category and Product names, 
-- and the price of each product, with the price formatted as US dollars?
-- Order the result by the Category and Product!

Create Function fCategoriesProductsAndPrice() 
 Returns Table 
 As
   Return(
    Select Top 1000000000
	 c.CategoryName, 
	 p.ProductName, 
	 UnitPrice = Format(p.UnitPrice, 'C', 'en-US') 
	 From vCategories as c Join vProducts as p
	 On c.CategoryID = p.CategoryID
    Order By 1, 2
	);
Go

-- Check that it works
Select * From dbo.fCategoriesProductsAndPrice(); 

-- Question 3 (10 pts): What function can you use to show a list of Product names, 
-- each Inventory Date, and the Inventory Count, with the date formatted like "January, 2017?" 
-- Order the results by the Product, Date, and Count!

Create Function fProductsInventoryDateAndCount() 
 Returns Table 
 As
   Return(
    Select Top 1000000000
	 p.ProductName, 
	 InventoryDate = DateName(mm,i.InventoryDate) + ', ' + DateName(yyyy, i.InventoryDate),
	 InventoryCount = i.Count
     From vProducts as p Join vInventories as i
     On p.ProductID = i.ProductID
    Order By 1, DatePart(Month, InventoryDate), 3 
	);
Go

-- Check that it works
Select * From dbo.fProductsInventoryDateAndCount() 

-- Question 4 (10 pts): How can you CREATE A VIEW called vProductInventories 
-- That shows a list of Product names, each Inventory Date, and the Inventory Count, 
-- with the date FORMATTED like January, 2017? Order the results by the Product, Date,
-- and Count!

Create View vProductInventories
As
 Select TOP 1000000000
   p.ProductName, 
   InventoryDate = DateName(mm,i.InventoryDate) + ', ' + DateName(yyyy, i.InventoryDate),
   InventoryCount = i.Count
  From vProducts as p Join vInventories as i
  On p.ProductID = i.ProductID
  Order By 1, DatePart(Month, InventoryDate), 3 
Go

-- Check that it works: 
Select * From vProductInventories;
Go

-- Question 5 (15 pts): How can you CREATE A VIEW called vCategoryInventories 
-- that shows a list of Category names, Inventory Dates, 
-- and a TOTAL Inventory Count BY CATEGORY, with the date FORMATTED like January, 2017?

Create View vCategoryInventories
As
Select TOP 1000000000 
	c.[CategoryName], 
	InventoryDate = DateName(mm,i.InventoryDate) + ', ' + DateName(yyyy, i.InventoryDate), 
	InventoryCountsByCategory= SUM(i.[Count])
  From vCategories as c
  Join vProducts as p
    On c.CategoryID = p.CategoryID
  Join vInventories as i 
    On i.ProductID = p.ProductID
	Group By c.CategoryName, i.InventoryDate
	Order By 1, DatePart(Month, InventoryDate), 3
Go

-- Check that it works: 
Select * From vCategoryInventories;
Go

-- Question 6 (10 pts): How can you CREATE ANOTHER VIEW called 
-- vProductInventoriesWithPreviouMonthCounts to show 
-- a list of Product names, Inventory Dates, Inventory Count, AND the Previous Month
-- Count? Use a functions to set any null counts or 1996 counts to zero. Order the
-- results by the Product, Date, and Count. This new view must use your
-- vProductInventories view!

Create View vProductInventoriesWithPreviousMonthCounts
As
 Select TOP 1000000000
   ProductName, 
   InventoryDate,
   InventoryCount,
   PreviousMonthCount = IIF(Month(InventoryDate) = 1, 0, ISNULL(Lag(InventoryCount) Over(Order By ProductName, Month(InventoryDate)), 0))
  From vProductInventories
  Group By ProductName, InventoryDate, InventoryCount
  Order By 1, DatePart(Month, InventoryDate), 3 
Go

-- Check that it works: 
Select * From vProductInventoriesWithPreviousMonthCounts;
Go

-- Question 7 (15 pts): How can you CREATE one more VIEW 
-- called vProductInventoriesWithPreviousMonthCountsWithKPIs
-- to show a list of Product names, Inventory Dates, Inventory Count, the Previous Month 
-- Count and a KPI that displays an increased count as 1, 
-- the same count as 0, and a decreased count as -1? Order the results by the Product, Date, and Count!

Create View vProductInventoriesWithPreviousMonthCountsWithKPIs
As
 Select TOP 1000000000
   ProductName, 
   InventoryDate,
   InventoryCount,
   PreviousMonthCount,
   CountVsPreviousCountKPI = IsNull(Case 
   When InventoryCount > PreviousMonthCount Then 1
   When InventoryCount = PreviousMonthCount Then 0
   When InventoryCount < PreviousMonthCount Then -1
   End, 0)
  From vProductInventoriesWithPreviousMonthCounts
  Order By 1, DatePart(Month, InventoryDate), 3 
Go

-- Check that it works: 
Select * From vProductInventoriesWithPreviousMonthCountsWithKPIs;
Go

-- Question 8 (25 pts): How can you CREATE a User Defined Function (UDF) 
-- called fProductInventoriesWithPreviousMonthCountsWithKPIs
-- to show a list of Product names, Inventory Dates, Inventory Count, the Previous Month
-- Count and a KPI that displays an increased count as 1, the same count as 0, and a
-- decreased count as -1 AND the result can show only KPIs with a value of either 1, 0,
-- or -1? This new function must use you
-- ProductInventoriesWithPreviousMonthCountsWithKPIs view!
-- Include an Order By clause in the function using this code: 
-- Year(Cast(v1.InventoryDate as Date))
-- and note what effect it has on the results.

Create Function fProductInventoriesWithPreviousMonthCountsWithKPIs(@Value int) 
 Returns Table 
 As
   Return(
    Select Top 1000000000
	  ProductName, 
      InventoryDate,
      InventoryCount,
      PreviousMonthCount,
      CountVsPreviousCountKPI
	  From vProductInventoriesWithPreviousMonthCountsWithKPIs
	  Where CountVsPreviousCountKPI = @Value
	  Order By Year(Cast(InventoryDate as Date))
	);
Go

-- Check that it works:
Select * From dbo.fProductInventoriesWithPreviousMonthCountsWithKPIs(1);
Go

Select * From dbo.fProductInventoriesWithPreviousMonthCountsWithKPIs(0);
Go

Select * From dbo.fProductInventoriesWithPreviousMonthCountsWithKPIs(-1);
Go

/***************************************************************************************/