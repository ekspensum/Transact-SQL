--PROCEDURY
--Zadanie 1.1 
--Prosz� napisa� procedur� sk�adowan�, kt�ra wypisze dane wszystkich produkt�w (tabela Products, baza danych Northwind), kt�rych cena jednostkowa jest wi�ksza lub r�wna cenie podanej jako argument procedury. Produkty maj� by� posortowane malej�co wed�ug ceny i  rosn�co wed�ug nazwy (je�li cena by�aby jednakowa dla pewnych produkt�w).
--create proc pr_products_price(@price float)
alter proc pr_products_price(@price money=30)
AS
select * from Products where UnitPrice >= @price order by UnitPrice desc, ProductName
go
exec pr_products_price 25.34

alter proc pr_products_price(@price1 money=2.5, @price2 money=14)
as
set nocount on
select * from Products where UnitPrice between @price1 and @price2 order by UnitPrice desc, ProductName
go
exec pr_products_price 

--Zadanie 1.2
--Prosz� napisa� procedur� sk�adowan�, kt�ra wypisze wszystkie produkty z kategorii, kt�rej nazwa podana jest jako parametr, przy czym chodzi tylko o produkty o najwy�szej cenie w tej kategorii. Procedura powinna mie� r�wnie� parametr wyj�ciowy (OUTPUT), kt�rego warto�� ma by� ustawiona w procedurze na liczb� produkt�w w podanej kategorii.
alter proc pr_products_by_category(@category varchar(20), @howMatchShow int, @quantityProdInCat int output)
as
set nocount on
select top(@howMatchShow) * from Products INNER JOIN Categories on Products.CategoryID = Categories.CategoryID where CategoryName = @category order by UnitPrice desc
SET @quantityProdInCat = (select count(ProductID) from Products INNER JOIN Categories on Products.CategoryID = Categories.CategoryID where CategoryName = @category)
select @quantityProdInCat
go
declare @quantityProdInCat int
exec pr_products_by_category 'beverages', 3, @quantityProdInCat out
select * from Categories

--Zadanie 1.3
--Prosz� napisa� procedur� sk�adowan�, kt�ra b�dzie s�u�y� do dopisywania jednego wiersza do tabeli [Order Details].
--Cena jednostkowa ma by� przepisywana z tabeli Products.
select * from products where ProductID = 1
select * from Orders order by OrderID
select * from [Order Details] inner join orders on [Order Details].OrderID = Orders.OrderID
go
alter proc pr_addOneRowDetail(@idOrder int, @idProduct int, @quantity int, @discount float)
AS
set nocount on
declare @price float
declare @unitInStock int
if not exists (select ProductID from Products where ProductID = @idProduct)
begin
raiserror ('Nie ma produktu o podanym id %d', 16, 1, @idProduct)
return (1)
end
if @quantity > (select UnitsInStock from Products where ProductID = @idProduct)
begin
raiserror('Nie ma wystarczaj�cej ilo�ci produktu %d', 16, 1, @idProduct)
return (2)
end
if exists (select * from [Order Details] where OrderID = @idOrder and ProductID = @idProduct)
begin
raiserror('Istnieje ju� zam�wienie dla produktu o id %d', 16, 1, @idProduct)
return (3)
end
if not exists (select * from Orders where OrderID = @idOrder)
begin
raiserror('Brak zam�wienia o id = %d', 16, 1, @idOrder)
return (4)
end
set @unitInStock = (select UnitsInStock from Products where ProductID = @idProduct)
set @price = (select UnitPrice from Products where ProductID = @idProduct)
update Products set UnitsInStock = @unitInStock - @quantity where ProductID = @idProduct
insert into [Order Details] values(@idOrder, @idProduct, @price, @quantity, @discount)
go
exec pr_addOneRowDetail 10, 1, 10, 0.15
delete from [Order Details] where OrderID = 10248 and ProductID = 1
DECLARE @return_status int;  
EXEC @return_status = pr_addOneRowDetail 10248, 10, 100000, 0.15;  
SELECT 'Return Status' = @return_status;  
GO 

--Zadanie 1.4
--Napisz procedur� zwi�kszaj�c� cen� wybranego produktu o 10% gdy cena jest ni�sza od 20 i o 5% gdy cena jest wy�sza od 20
select * from Products where ProductID = 1
alter proc pr_incrase_price(@idProduct int)
as
set nocount on
update Products set UnitPrice = 
case
when UnitPrice <20 then UnitPrice * 1.1
when UnitPrice >=20 then UnitPrice * 1.05
--else UnitPrice
end
where ProductID = @idProduct
go
exec pr_incrase_price 1

--Zadanie 1.5
--Napisz procedur� sk�adowan�, kt�ra wypisze nazwy tych produkt�w z tabeli Products w bazie danych Northwind, kt�re maj� najwy�sz� cen� (cena przechowywana jest w polu UnitPrice).
use Northwind
create proc pr_products_highest_price(@quantity int)
AS
begin
select top (@quantity) productName, unitPrice from products order by UnitPrice desc
end
go
exec pr_products_highest_price 5
go
--Zadanie 1.6
--Napisz procedur� sk�adowan�, kt�ra do tabeli BestCustomer (nale�y j� wcze�niej utworzy�) wpisze dane klienta lub klient�w (z tabeli Customers), kt�ry (kt�rzy) z�o�y� (z�o�yli) zam�wienia na najwi�ksz� kwot�, przy czym chodzi tu o sum� kwot na wszystkich zam�wieniach odbiorc�w. Informacja o zam�wieniach znajduje si� w tabelach Orders i [Order�Details]. Procedura wpisze do tabeli dane jednego klienta lub kilku, gdyby zdarzy�o si�, �e kilku z�o�y�o zam�wienia na identyczn� najwi�ksz� kwot�.
alter proc pr_best_customers
AS
declare @custTable table (id int, custId varchar(5), quality float)
insert into @custTable  
select rownum = row_number() over (order by SUM(unitPrice * quantity) desc), customers.customerID, SUM(unitPrice * quantity) as quality from customers INNER JOIN Orders ON customers.CustomerID = orders.customerID INNER JOIN [Order Details] ON orders.orderID = [order details].orderID GROUP BY customers.customerID order by quality desc

if not exists (select * from sysobjects where name = 'BestCustomer' and xtype = 'U') 
create table BestCustomer (
id int IDENTITY(1,1),
customerId varchar(5),
quality float)
delete from BestCustomer
declare @tempid int = 1
WHILE @tempid <= (select top 1(id) from @custTable order by id desc)
begin
if (select quality from @custTable where id = @tempid) = (select quality from @custTable where id = (@tempid + 1))
begin
insert into BestCustomer(customerId, quality) values((select custId from @custTable where id = @tempid), (select quality from @custTable where id = @tempid)) 
set @tempid = @tempid + 1
end
else
insert into BestCustomer(customerId, quality) values((select custId from @custTable where id = @tempid), (select quality from @custTable where id = @tempid)) 
PRINT 'Bie��ca warto�� licznika to: '+ CAST(@tempid AS VARCHAR);
break
end
return
go
exec pr_best_customers
select * from BestCustomer

--Zadanie 1.7
--Zmodyfikuj procedur� z zadania 2 tak, by do tabeli BestCustomers wpisane by�y dane nie tylko klient�w, kt�rzy zam�wili na najwi�ksz� kwot�, ale r�wnie� tych, kt�rzy z�o�yli zam�wienia na kwot� drug� i trzeci� od g�ry.
alter proc pr_best_customers2(@customers int)
AS
declare @custTable table (id int, custId varchar(5), quality float)
insert into @custTable  
select rownum = row_number() over (order by SUM(unitPrice * quantity) desc), customers.customerID, SUM(unitPrice * quantity) as quality from customers INNER JOIN Orders ON customers.CustomerID = orders.customerID INNER JOIN [Order Details] ON orders.orderID = [order details].orderID GROUP BY customers.customerID order by quality desc

if not exists (select * from sysobjects where name = 'BestCustomer2' and xtype = 'U') 
create table BestCustomer2 (
id int not null,
customerId varchar(5),
quality float
primary key(id))
delete from BestCustomer2
declare @tempid int = 1
WHILE @tempid <= @customers
begin
insert into BestCustomer2 values((select id from @custTable where id = @tempid), (select custId from @custTable where id = @tempid), (select quality from @custTable where id = @tempid)) 
set @tempid = @tempid + 1
end
return
go
exec pr_best_customers2 5
select * from BestCustomer2

--FUNKCJE
use Northwind
select * from [Order Details] where ProductID = 41
select ProductID, UnitPrice, ROW_NUMBER() OVER (order by ProductID) from [Order Details] where ProductID = 1
--Zadanie 2.1
--Napisz funkcj� obliczaj�c� �redni� cen� produktu z tabeli Order Details
alter function fn_average_price(@idProduct int)
returns float
as
begin
declare @tempTable table (id int, price float)
declare @sumPrice float = 0;
declare @records int = 1;
insert into @tempTable select ROW_NUMBER() OVER (order by ProductID), UnitPrice from [Order Details] where ProductID = @idProduct;
while @records <= (select count(Northwind.dbo.[Order Details].OrderID) from Northwind.dbo.[Order Details] where Northwind.dbo.[Order Details].ProductID = @idProduct)
begin
set @sumPrice = @sumPrice + (select price from @tempTable where id = @records);
set @records = @records + 1;
end
return (@sumPrice / @records)
end
go
select dbo.fn_average_price(15)

--Zadanie 2.2
--Napisz funkcj� znajduj�c� zam�wienia o najwy�szej warto�ci
use Northwind
select top 1 Customers.CompanyName, Products.ProductName, [Order Details].UnitPrice * Quantity as quality from [Order Details] inner join Orders on [Order Details].OrderID = Orders.OrderID inner join Products on [Order Details].ProductID = Products.ProductID inner join Customers on Orders.CustomerID = Customers.CustomerID order by ([Order Details].UnitPrice * Quantity) desc
go
alter function fn_bestOrder(@orders int)
returns @bestOrder table (companyName varchar(50), productName varchar(35), quality money)
as
begin
insert into @bestOrder select top(@orders) Customers.CompanyName, Products.ProductName, [Order Details].UnitPrice * Quantity as quality from [Order Details] inner join Orders on [Order Details].OrderID = Orders.OrderID inner join Products on [Order Details].ProductID = Products.ProductID inner join Customers on Orders.CustomerID = Customers.CustomerID order by ([Order Details].UnitPrice * Quantity) desc;
return
end
go
select * from dbo.fn_bestOrder(15)

--Zadanie 2.3
--Napisz funcj� znajduj�c� 
alter function fn_maxQuantity()
returns @maxQuantityByProducts table (idProduct int, productName varchar(35), maxQuantity int)
as
begin
insert into @maxQuantityByProducts select [Order Details].ProductID, Products.ProductName, max(quantity) from [Order Details] inner join Products on Products.ProductID = [Order Details].ProductID group by [Order Details].ProductID, Products.ProductName order by max(quantity) desc;
return
end
go
select * from dbo.fn_maxQuantity()

--Zadanie 2.4
--Napisz funkcj� obliczaj�c� pole powierzchni ko�a
go
alter function circleArea(@radius int)
returns decimal(8,4)
as
begin
return @radius*@radius*3.14
end
go
select dbo.circleArea(13) as CA

--TRIGGERY
--Zadanie 3.1
--Napisz trigger blokuj�cy dodawanie rekord�w do tabeli Order Details
use Northwind
go
create trigger tr_block_insert
on [Order Details]
after insert
as
rollback
raiserror('Dopisywanie rekord�w zabronione', 16, 1)
go
insert into [Order Details] values(10248, 5, 20, 1, 0)

--Zadanie 3.2
--Zmie� powy�szy trigger tak, by by� uruchamiany dla zdania UPDATE
--i wypiszmy zawarto�� tabel T1, deleted i inserted.
--UWAGA!!!!! Normalnie wyzwalacz nie powinien nic wypisywa�, 
--poniewa� dzia�a "w tle". My wypisujemy tylko dla cel�w poznawczych.
alter trigger tr_block_insert
on [Order Details]
--with encryption
after update
as
select * from deleted
select * from inserted
rollback
go
select * from [Order Details]
update [Order Details] set Quantity = 10 where OrderID = 10248 and ProductID = 1

--Zadanie 3.3
--Zmie� powy�szy wyzwalacz - u�yj instead of i usu� rollback
alter trigger tr_block_insert
on [Order Details]
instead of update
as
select * from deleted
select * from inserted
go
update [Order Details] set Quantity = 10 where OrderID = 10248 and ProductID = 1
select * from [Order Details]
alter table [Order Details] disable trigger tr_block_insert

--Zadanie 3.4
--Napisz trigger na tabeli Products uruchamiaj�cy si� przy update kolumny UnitPrice i uniemo�liwaj�cy zmian� ceny, gdy ilo�� jest = 0
alter trigger tr_onUpdatePrice
on Products
after update
as
if UPDATE(UnitPrice)
begin
if exists (select UnitsInStock from deleted where UnitsInStock = 0)
	begin
	raiserror('Nie mo�na zmienia� ceny produktu gdy jego ilo�� jest = 0',16,1)
	rollback
	end
end
go
select * from Products where UnitsInStock = 0
update Products set UnitPrice = 
case 
when UnitsInStock > 0 then 10
else UnitPrice
end
where ProductID = 5 
update Products set UnitPrice = 18 where ProductID = 1

--Zadanie 3.5
--Napisz wyzwalacz, kt�ry wprowadzi poprawn� cen� pobran� z tabeli Products przy wstawianiu rekordu do tabeli Order Details (je�eli wstawiana cewna jest inna)
--Na razie b�dzie to uproszczona wersja, kt�ra zadzia�a
--bez b��du tylko, jesli jednym zdaniem INSERT dodamy
--tylko jeden rekord do tabeli [Order Details]
create trigger tr_correctPrice
on [Order Details]
after insert
as
declare @priceFromProducts money
declare @priceFromInserted money
declare @idProduct int
declare @idOrder int
set @priceFromInserted = (select UnitPrice from inserted)
set @idProduct = (select ProductID from inserted)
set @idOrder = (select OrderID from inserted)
set @priceFromProducts = (select UnitPrice from Products where ProductID = @idProduct)
if @priceFromInserted <> @priceFromProducts
begin
update [Order Details] set UnitPrice = @priceFromProducts where OrderID = @idOrder and ProductID = @idProduct
raiserror('Skorygowano cen� produktu na cen� pobran� z tabeli Products', 16,1)
end
go
select * from [Order Details] where OrderID = 10248
select * from Products where ProductID = 5
insert into [Order Details] values(10248, 5, 21.35, 1, 0)
delete from [Order Details] where OrderID = 10248 and ProductID = 5

use Northwind
--Zadanie 3.6
--Zmodyfikuj trigger jak wy�ej tak aby dzia�a� gdy wstawianych jest wi�cej ni� 1 wiersz
go
alter trigger tr_correctPrice
on [Order Details]
with encryption
after insert
as
declare @dataFromInserted table (id int, idOrder int, idProduct int, price money)
insert into @dataFromInserted select ROW_NUMBER() over(order by OrderID), OrderID, ProductID, UnitPrice from inserted
declare @idProduct int
declare @idOrder int
declare @priceFromProducts money
declare @i int = 1
while @i <= (select count(id) from @dataFromInserted)
begin
set @priceFromProducts = (select UnitPrice from Products where ProductID = (select idProduct from @dataFromInserted where id = @i))
if @priceFromProducts <> (select price from @dataFromInserted where id = @i)
update [Order Details] set UnitPrice = (select UnitPrice from Products where ProductID = (select idProduct from @dataFromInserted where id = @i)) where OrderID = (select idOrder from @dataFromInserted where id = @i) and ProductID = (select idProduct from @dataFromInserted where id = @i)
set @i = @i + 1
end
go
select * from [Order Details] where OrderID = 10248
select * from [Order Details] where ProductID = 2
select * from Products where ProductID = 2
insert into [Order Details] values(10248, 5, 1, 1, 0), (10248, 6, 1, 1, 0), (10248, 7, 1, 1, 0)
delete from [Order Details] where OrderID = 10248 and ProductID = 7
--inny spos�w rozwi�zania zadania jak wy�ej bez sprawdzania poprawno�ci ceny:
go
alter trigger tr_correctPrice
on [Order Details]
instead of insert
as
set nocount on
insert into [Order Details] select OrderID, ProductID, (select UnitPrice from Products where ProductID = ins.ProductID), Quantity, Discount from inserted as ins
go

--Zadanie	3.7	
--Prosz�	napisa�	wyzwalacz,	kt�ry	b�dzie	kontrolowa�	wpisywanie	nowych	wierszy	do	tabeli	[Order	Details].	
--Wyzwalacz,	kt�ry	przepisywa�	cen�	towaru	z	tabeli	Products	do	tabeli	[Order	Details]	by�	ju�	wcze�niej	skonstruowany.	
--Nale�y	go	uzupe�ni�	o	sprawdzanie	i	aktualizacj�	p�l	UnitsInStock	oraz	UnitsOnOrder.	
--Je�li	nie	ma	odpowiedniej	liczby	sztuk	towaru,	to	nale�y	operacj�	dopisania	wiersza	wycofa�.	
--Analogicznie	mo�na	napisa�	wyzwalacz,	kt�ry	b�dzie	kontrolowa�	aktualizacj�	pola	Quantity	w	tabeli	[Order	Details]	
--oraz	odpowiednio	modyfikowa�	pola	UnitsInStock	i	UnitsOnOrder	w	tabeli	Products.	
alter trigger tr_correctPrice
on [Order Details]
for insert
as
declare @tempTable table (id int, price money, quantity int, idProduct int, idOrder int)
declare @idProduct int
declare @i int = 1
insert into @tempTable select ROW_NUMBER() over(order by OrderID), UnitPrice, Quantity, ProductID, OrderID from inserted
while @i <= (select count(id) from @tempTable)
begin
if (select UnitsInStock from Products where ProductID = (select idProduct from @tempTable where id = @i)) < (select quantity from @tempTable where id = @i)
	begin
	set @idProduct = (select idProduct from @tempTable where id = @i)
	raiserror('Brak wystarczaj�cej ilo�ci produktu o nr id: %d', 16, 1, @idProduct)
	rollback
	return
	end
else
	begin
	update [Order Details] set UnitPrice = (select UnitPrice from Products where ProductID = (select idProduct from @tempTable where id = @i)) where OrderID = (select idOrder from @tempTable where id = @i) and ProductID = (select idProduct from @tempTable where id = @i)
	update Products set UnitsInStock = (UnitsInStock - (select quantity from @tempTable where id = @i)) where ProductID = (select idProduct from @tempTable where id = @i)
	end 
set @i = @i + 1
end
go
select * from [Order Details] where OrderID = 10248
select * from [Order Details] where ProductID = 1
select * from Products where ProductID = 7
update Products set UnitsInStock = 1 where ProductID = 5
insert into [Order Details] values(10248, 5, 1, 1, 0), (10248, 6, 1, 1, 0), (10248, 7, 1, 1, 0)
delete from [Order Details] where OrderID = 10248 and ProductID = 5
update [Order Details] set UnitPrice = 34.80 where OrderID = 10248 and ProductID = 72

--Zadanie 3.7
--Utw�rzmy wyzwalacz, kt�ry b�dzie rejestrowa� zmiany cen
--produkt�w w tabeli Products. Informacja o zmianach
--ma by� wpisywana do tabeli Products_Log:
use Northwind
drop table [dbo].[Products_log]
go
create table Products_log (
id int primary key identity,
 date_and_time datetime,
 who varchar(25),
 idProduct int,
 oldPrice money,
 newPrice money
 )
 go
create trigger tr_saveChangedPrice
 on [dbo].[Products]
 after update
 as
 set nocount on
 if UPDATE(UnitPrice)
 insert into Products_log([date_and_time], [who], idProduct, oldPrice, newPrice) select GETDATE(), SYSTEM_USER, deleted.ProductID, deleted.UnitPrice, inserted.UnitPrice from deleted inner join inserted on deleted.ProductID = inserted.ProductID
go
select * from Products where ProductID in(1,18)
update Products set UnitPrice = 18 where ProductID in(1,18)
select * from Products_log

--Zadanie 3.8
--Prosz� napisa� wyzwalacz, kt�ry nie pozwoli na wykonanie zdania UPDATE
--(tj. wykona ROLLBACK), je�li warto�� w kolumnie k2 zmieni si�
--w przynajmniej jednym zmienianym rekordzie na mniejsz�:
use Northwind
go
alter trigger tr_changePriceRollback
on [dbo].[Products]
after update
as
if UPDATE(UnitPrice)
begin
	if (select UnitPrice from deleted where ProductID = 18) > (select UnitPrice from inserted where ProductID = 18)
	begin
		print 'Niedozwolna zmiana ceny na ni�sz� przez: '+System_User
		rollback
	end
end
go
--Zadanie 3.9
--Teraz zmie�my spos�b dzia�ania wyzwalacza - 
--Tym razem chcemy, �eby zmiany UnitPrice na warto�� wi�ksz� by�y akceptowane
--a nie wykonaj� si� tylko te na warto�� mniejsz�. Oczywi�cie
--chodzi o zmiany wykonane jednym zdaniem UPDATE.
alter trigger tr_changePriceRollback
on Products
instead of update
as
declare @tempTable table(id int identity, idProduct int, oldPrice money, newPrice money)
declare @idProduct int
declare @i int = 1
if UPDATE(UnitPrice)
begin
insert into @tempTable select deleted.ProductID, deleted.UnitPrice, inserted.UnitPrice from deleted inner join inserted on deleted.ProductID = inserted.ProductID order by ProductID
while @i <= (select COUNT(id) from @tempTable)
	begin
		if (select oldPrice from @tempTable where id = @i) > (select newPrice from @tempTable where id = @i)
		begin
			set @idProduct = (select idProduct from @tempTable where id = @i)
			print 'Niedozwolona zmiana ceny na ni�sz� produktu id = '+cast(@idProduct as varchar(3))+' przez u�ytkownika: '+system_user
		end
		else
		begin
			update Products set UnitPrice = (select newPrice from @tempTable where id = @i) where ProductID = (select idProduct from @tempTable where id = @i)
		end
		set @i = @i + 1
	end
end
go
select * from Products where ProductID in(1,18)
update Products set UnitPrice = 41 where ProductID in(1,18)
select * from Products_log order by date_and_time desc
enable trigger [tr_changePriceRollback] on Products

--Zadanie 3.10
--Napisa� wyzwalacz, kt�ry pozwoli na dopisanie do
--tabeli SF (Szczeg�y faktur) tylko 
--poprawnych numer�w towaru lub us�ugi.
--Numery towar�w s� w tabeli Towary, numery
--us�ug s� w tabeli Us�ugi, wii�c nie da si�
--utworzy� wi�z�w klucza obcego w tabeli SF
--(bo klucz obcy mo�e si� odwo�ywa� tylko do 
--jednej tabeli.

use test

create table services (
id int primary key check(id >= 100),
serviceName varchar(20),
laborPrice money
)
create table products (
id int primary key check(id < 100),
productName varchar(25),
price money
)
create table invoices (
id int check(id >=1000),
ServiceOrProductId int,
quantity int
primary key (id, ServiceOrProductId)
)
go
insert into services values(101, 'usluga1',100), (102, 'usluga2', 200), (103, 'usluga3', 300)
insert into products values(1, 'produkt1', 10), (2, 'produkt2', 20), (3, 'produkt3', 30)
select * from services
select * from products
go
create trigger tr_checkoutServiceOrProductId
on invoices
after insert
as
if exists (select * from inserted where ServiceOrProductId not in (select id from services) and ServiceOrProductId not in (select id from products))
begin
print 'Numer id us�ugi lub produktu jest nieprawid�owy'
rollback
end
go
insert into invoices values(1000, 101, 7), (1000, 3, 1), (1000, 102, 13)
insert into invoices values(1001, 103, 7), (1001, 2, 12), (1001, 101, 17)
select * from invoices order by id desc

--Zadanie 3.11
--Inna wersja powy�szego wyzwalacza. Tym razem chcemy, �eby wyzwalacz
--pozwala� na wpisanie poprawnych numer�w towar�w 
--i us�ug a odrzuca� tylko te niepoprawne
go
alter trigger tr_checkoutServiceOrProductId
on invoices
instead of insert
as
insert into invoices select * from inserted where ServiceOrProductId in (select id from services) or ServiceOrProductId in (select id from products)
go
insert into invoices values(1002, 103, 71), (1002, 21, 12), (1002, 101, 171)
go

--TRANSAKCJE
--Zadanie 4.1
--Sprawd� dzia�anie transakcji w trybie jawnym.
use test
create table t2 (
id int primary key not null,
p1 varchar(2) )
go
insert into t2 values(1,'a'), (2, 'b'), (3, 'c')
select * from t2
set implicit_transactions off --ustawienie domy�lne
set xact_abort off --ustawienie domy�lne
go
begin tran
insert into t2 values(4, 'd')
insert into t2 values(1, 'a')
commit
select * from t2 --rekord 4 d zosta� dodany pomimo b��du w transakcji
go
set xact_abort on --w��czenie rollback przy zaistnieniu b��du
begin tran
insert into t2 values(5, 'e')
insert into t2 values(1, 'a')
commit
select * from t2 --rekord 5 e nie zosta� dodany
go

--uzycie transakcji przez testowanie
begin tran
insert into t2 values(5, 'e')
insert into t2 values(1, 'a')
if @@ERROR <> 0
	rollback
else
	commit
select * from t2 --rekord 5 e nie zosta� dodany

--uzycie transakcji przy zastosowaniu try catch
set xact_abort off 
begin try
	begin tran
	insert into t2 values(5, 'e')
	insert into t2 values(1, 'a')
	commit
end try
begin catch
	rollback
end catch
select * from t2 --rekord 5 e nie zosta� dodany

--Zadanie 4.2 
--Sprawd�, jak system zachowa si� przy pr�bie zagnie�d�ania transakcji (wewn�trz ju� dzia�aj�cej transakcji rozpoczniemy now�).
use test
delete from t2
begin tran
print @@Trancount
insert into t2 values(1, 'a')
begin tran
print @@Trancount
insert into t2 values(2, 'b')
commit
print @@Trancount
rollback
select * from t2

--inna wersja:
begin tran
print @@Trancount
insert into t2 values(1, 'a')
begin tran
print @@Trancount
insert into t2 values(2, 'b')
rollback
print @@Trancount
insert into t2 values (3, 'c')
commit
select * from t2

--Zadanie 4.3
--Rozwa�my tabel� Konta(NrKonta INT PRIMARY KEY, Stan MONEY).
--Prosz� napisa� procedur�, kt�ra wykona przelew z konta @kt1 na konto @kt2. 
--Niezale�nie od procedury zak�adamy, �e w systemie mog� by� mechanizmy, kt�re uniemo�liwi� pobranie z konta takiej kwoty, 
--kt�ra spowoduje, �e stan konta b�dzie ni�szy ni� pewien pr�g (np. 0 albo 100). 
--Podobnie dopuszczamy ewentualne narzucanie innych warunk�w, np. �e na koncie przez pewien czas nie mo�na wykonywa� �adnych operacji zmian, 
--albo, �e stan konta nie mo�e przekroczy� pewnej kwoty.
--Procedura ma wykona� przelew w spos�b atomowy. W razie niepowodzenia maj� by� wycofane tylko operacje z procedury.

use test
create table konta (
nrKonta int primary key not null,
stan money )
go
insert into konta values(1, 1000), (2, 1300)
update konta set stan = 1300 where nrKonta = 1
go
alter proc pr_BankTransfer(@from int, @to int, @quality money)
as
begin try
	begin tran
	update konta set stan = stan - @quality where nrKonta = @from
	update konta set stan = stan + @quality where nrKonta = @to
	if (select stan from konta where nrKonta = @from) >= 0 
	and exists (select * from konta where nrKonta = @from) 
	and exists (select * from konta where nrKonta = @to)
		commit
	else
		raiserror('Brak wystarczaj�cych �rodk�w lub nr konta jest niew�a�ciwy', 17,2)
end try
begin catch
	raiserror('Brak wystarczaj�cych �rodk�w lub nr konta jest niew�a�ciwy', 16,1)
	rollback
end catch 
go
exec pr_BankTransfer 1, 2, 1400
select * from konta

--BACKUP
use master
select * from sysobjects where xtype in ('U', 'X')
go
--Zadanie 5.1 
--Odtwarzanie systemu bazy danych po awarii dysku z danymi (zak�adamy, �e dysk z dziennikiem transakcji nie uleg� uszkodzeniu). 
use test
select * from sys.databases
select * from INFORMATION_SCHEMA.TABLES
create table t1 (
id int primary key identity,
col1 int )
insert into t1 values(100), (200), (300), (400)
backup database test to disk='G:\test_pelna_kopia.bak'
insert into t1 values (500), (600)
backup database test to disk='G:\test_kopia_roznicowa.bak' with differential
insert into t1 values (700), (800)
backup database test to disk='G:\T-SQL\test_roznicowa2.bak' with differential
insert into t1 values(900), (1000)
backup database test to disk='g:\t-sql\test_roznicowa3.bak' with differential
backup LOG test to disk='g:\t-sql\test_log.bak'
insert into t1 values (1100), (1200)
backup log test to disk='g:\t-sql\test_log2.bak'
insert into t1 values (1300), (1400)
begin tran
go
insert into t1 values (1500), (1600)
--awaria bazy (usuni�cie pliku bazy)
--proces odtwarzania bazy:
use master
use test
backup log test to disk='g:\t-sql\test_log3.bak' with no_truncate
go
restore database test from disk='g:\t-sql\test_pelna_kopia.bak' with standby='g:\t-sql\test.tmp'
select * from t1
restore database test from disk='g:\t-sql\test_roznicowa3.bak' with standby='g:\t-sql\test.tmp'
go
restore log test from disk='g:\t-sql\test_log2.bak' with standby='g:\t-sql\test.tmp'
go
restore log test from disk='g:\t-sql\test_log3.bak' with standby='g:\t-sql\test.tmp'
go
restore log test from disk='g:\t-sql\test_log3.bak' with recovery
go
restore database test from disk='g:\t-sql\test_roznicowa3.bak' with standby='g:\t-sql\test.tmp'
restore log test from disk='g:\t-sql\test_log.bak' with standby='g:\t-sql\test.tmp'
print @@trancount
