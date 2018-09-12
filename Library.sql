-- This application is about Public Library transections Like barrowing and returning the  books / CDs.
-- Application allows at any time, one person can holds 3 books and 2 CDS.
-- Books need to be returned with in 14 days
-- CD's need to be returned with in 7 days
-- Fine $0.5 for book per day after 14 days (starts from 15th day)
-- Fine $0.75 for CD per day after 7 days (starts from 8 day)
-- IF some body lost the book / CD, That person needs to pay that item cast. In this case,  system will delete this item from inventory.
-- one can search his/ her due dates for returning CDs/ Books
-- one can search his due amounts
-- no need to enter the date of transections. System will pick current date.

CREATE DATABASE Library
GO
USE Library

GO

CREATE TABLE CusDetails

(
	CusId int IDENTITY(10000,1) NOT NULL,
	CusName nvarchar(50) NOT NULL,
	Phone nchar(12) NULL,
	Email nvarchar(50) NULL,
       CONSTRAINT PK_CusDetails PRIMARY KEY CLUSTERED (CusId ASC)
)
GO

insert into CusDetails values ('Cus1', '111-111-1111', 'Cus1@gmail.com');
insert into CusDetails values ('Cus2', '111-111-1234', 'Cus2@gmail.com');
insert into CusDetails values ('Cus3', '111-111-1345', 'Cus3@gmail.com');
insert into CusDetails values ('Cus4', '111-111-4567', 'Cus4@gmail.com');
insert into CusDetails values ('Cus5', '111-111-5678', 'Cus5@gmail.com');

GO

CREATE TABLE Inventory

(
	InvenId int IDENTITY(1000,1) NOT NULL,
	InvenType nchar(10) NOT NULL,  -- "b" for Book and "c" for CD
	InvName nvarchar(50) NOT NULL,
	Qty int NOT NULL,
	Cast money NOT NULL,
       CONSTRAINT PK_Inventory PRIMARY KEY CLUSTERED (InvenId ASC)
)

GO

insert into Inventory values ('b', 'book1', 2, 3.00);
insert into Inventory values ('b', 'book2', 1, 2.00);
insert into Inventory values ('b', 'book3', 3, 0.75);
insert into Inventory values ('b', 'book4', 2, 1.00);
insert into Inventory values ('b', 'book5', 1, 5.00);
insert into Inventory values ('c', 'CD5', 1, 8.00);
insert into Inventory values ('c', 'CD4', 2, 5.00);
insert into Inventory values ('c', 'CD3', 3, 2.00);
insert into Inventory values ('c', 'CD2', 2, 5.00);
insert into Inventory values ('c', 'CD1', 1, 8.00);
insert into Inventory values ('c', 'CD6', 4, 3.00);


CREATE TABLE TranTable

(
	TranId int IDENTITY(10000,1) NOT NULL,
	CusId int NOT NULL,
	InvenId int NOT NULL,
	Date date NOT NULL,
	dueDate date,
	ReturnedDate date NULL,
	Fine money NULL,
       CONSTRAINT PK_TranTable PRIMARY KEY CLUSTERED (TranId ASC)
 )

GO

-- For borrowing books/CDs

CREATE VIEW vInvenTran
AS
SELECT t.CusId, i.InvenType, t.ReturnedDate, t.InvenId FROM TranTable AS t 
INNER JOIN Inventory AS i 
ON t.InvenId = i.InvenId

GO

CREATE Procedure uspBorrow
@cusId int
, @invenId int
as
declare
@q int      -- quanty of perticular borrowed item
, @qbc int  --books or CDs
, @qty int  -- total qty in inventory
, @invenType nchar(10)
, @qc int
, @qb int
, @noOfDays date

select @invenType = (select invenType from Inventory where InvenId = @invenId)
select @q = (select count(*) from TranTable where (InvenId = @invenId and ReturnedDate is null ))
select @qty = (select qty from Inventory where InvenId = @invenId)
select @qbc = (select count(*) from vInvenTran where (InvenType = @invenType and ReturnedDate is null ))
select @qb = (select count(*) from vInvenTran where (InvenType = 'b' and CusId = @CusId and ReturnedDate is null ))
select @qc = (select count(*) from vInvenTran where (InvenType = 'c' and CusId = @CusId and ReturnedDate is null ))

if (@invenType='b')
   select @noOfDays = 14 + GETDATE();
else if @invenType='c'
select @noOfDays = 7 + getdate();


if ((@invenType='b' and @qb < 3) or (@invenType='c' and @qc < 2))
begin
	if (@q < @qty)
	begin
	insert into TranTable(CusId, InvenId, Date, dueDate) values (@cusId, @invenId, GETDATE(), @noOfDays)
		print 'You got the Item'
	end
	else
	    print 'Sorry this item is not available right now'
end
else
print 'You already exceded max quanty of this type of item (book or CD)'

GO

exec uspBorrow 10000, 1010
exec uspBorrow 10000, 1009
exec uspBorrow 10000, 1008
exec uspBorrow 10000, 1000
exec uspBorrow 10000, 1001
exec uspBorrow 10000, 1002
exec uspBorrow 10000, 1004
exec uspBorrow 10001, 1009

go

-- for showing fine, I am updating the borrowing date for one transection.
declare
@changedDate date
, @dDate date
select @changedDate = getdate() - 26;
select @dDate = getdate() + 14 - 26;

update TranTable
        set [Date] =  @changedDate 
		where (CusId = 10000 and InvenId = 1000)

update TranTable
        set dueDate = @dDate
		where (CusId = 10000 and InvenId = 1000)



GO
-- For retruning Books / CDs 
CREATE procedure uspReturn
@CusId int
, @InvenId int
as
declare
@returnDate date
, @days int
, @n int
, @borrowDate date
, @invenType nchar(10)
, @feeBook money
, @feeCD money
, @fee money

select @feeBook = 0.5
select @feeCD = 0.75
select @returnDate = getdate()

select @borrowDate = (select date from TranTable where (CusId = @CusId and InvenId = @InvenId))
  
        select @days = (DATEDIFF(day, @borrowDate, @returnDate))
		select @invenType = (select invenType from vInvenTran where (CusId = @CusId and InvenId = @InvenId))
		if (@invenType = 'b') 
		begin
		select @n = 14
		if (@n > @days)
		select @fee = 0
		else
		select @fee = (@days - @n) * @feeBook 
		end

		else if (@invenType = 'c')
		begin
		select @n = 7
		if (@n > @days)
		select @fee = 0
		else
		select @fee = (@days - @n) * @feeCD
		end

        update TranTable
        set ReturnedDate = @returnDate
		    , Fine = @fee where (CusId = @CusId and InvenId = @InvenId)
	
GO	
    
	EXEC uspReturn 10000, 1000



