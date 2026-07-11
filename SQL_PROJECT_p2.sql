create database library_management;
use library_management;

-- CREATE TABLE FOR BRANCH

DROP TABLE IF EXISTS branch;
create table branch(
branch_id VARCHAR(10) PRIMARY KEY,	
manager_id VARCHAR(10) ,	
branch_address VARCHAR(55),
contact_no VARCHAR(20)
);

select * from branch;

-- CREATE TABLE FOR EMPLOYEES
DROP TABLE IF EXISTS employees;
create table employees(
emp_id VARCHAR (20) PRIMARY KEY,
emp_name VARCHAR (25),
position VARCHAR (20),
salary	INT ,
branch_id VARCHAR (10) -- Foreign Key
);

select * from employees;

-- CREATE TABLE FOR BOOKS
DROP TABLE IF EXISTS books;
create table books(
isbn VARCHAR(20) PRIMARY KEY,
book_title	VARCHAR(75),
category VARCHAR(20),
rental_price FLOAT,
status VARCHAR(15),
author VARCHAR (35),
publisher varchar (55)
);

select * from books;

-- CREATE TABLE FOR ISSUED_STATUS
DROP TABLE IF EXISTS issued_status;
create table issued_status(
issued_id VARCHAR(10) PRIMARY KEY,
issued_member_id VARCHAR(10), -- Foreign Key
issued_book_name VARCHAR (75),
issued_date	DATE,
issued_book_isbn VARCHAR(25), -- Foreign Key
issued_emp_id VARCHAR(10) -- Foreign Key
); 

select * from issued_status;

-- CREATE TABLE FOR MEMBERS
DROP TABLE IF EXISTS members;
CREATE TABLE members(
member_id VARCHAR (35) PRIMARY KEY ,
member_name	VARCHAR (35) ,
member_address	VARCHAR (75) ,
reg_date DATE
);

select * from members;

-- CREATE TABLE FOR RETURN_STATUS
DROP TABLE IF EXISTS return_status;
CREATE TABLE return_status(
return_id	VARCHAR(10) PRIMARY KEY,
issued_id	VARCHAR(20),
return_book_name VARCHAR(75) ,
return_date	DATE,
return_book_isbn VARCHAR(20)
);

select * from return_status;


set SQL_SAFE_UPDATES=0;
-- FOREIGN KEY
Alter table issued_status
add constraint ForeignKey_members 
foreign key (issued_member_id) 
references members(member_id);

Alter table issued_status
add constraint ForeignKey_books
foreign key (issued_book_isbn) 
references books(isbn);

Alter table issued_status
add constraint ForeignKey_employees
foreign key (issued_emp_id) 
references employees(emp_id);

Alter table employees
add constraint ForeignKey_branch
foreign key (branch_id) 
references branch(branch_id);

Alter table return_status
add constraint ForeignKey_issued_status
foreign key (issued_id) 
references issued_status(issued_id);

-- Task 1. Create a New Book Record --
-- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

insert into books values 
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
select * from books;

-- Task 2: Update an Existing Member's Address
UPDATE members
set member_address = '125 Oak St'
where member_id='C103';
select * from members;

-- Task 3: Delete a Record from the Issued Status Table -- 
-- Objective: Delete the record with 
-- issued_id = 'IS121' from the issued_status table.

delete from issued_status
where issued_id = 'IS121' ;

-- Task 4: Retrieve All Books Issued by a Specific Employee -- 
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT * from issued_status
where issued_emp_id = 'E101';

-- Task 5: List Members Who Have Issued More Than One Book 
-- Objective: Use GROUP BY to find members who have issued more than one book.

select issued_emp_id, count(*)from issued_status
group by issued_emp_id
having count(*)>1
order by count(*) DESC;

-- CTAS (Create Table As Select)
-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results 
-- each book and total book_issued_cnt**

create table book_count AS
select b.isbn, count(ist.issued_id) as no_issued, b.book_title from 
books as b
JOIN 
issued_status as ist
ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title;

select * from book_count;

-- Task 7. Retrieve All Books in a Specific Category: 
select *from books
where category = 'Classic';


-- Task 8: Find Total Rental Income by Category:

select
b.category,
sum(b.rental_price),
count(*)
from 
books as b
JOIN 
issued_status as ist
ON ist.issued_book_isbn = b.isbn
GROUP BY b.category
order by sum(b.rental_price) DESC;

-- TASK 9 - List Members Who Registered in the Last 180 Days:

SELECT * FROM members
where reg_date >= CURRENT_DATE - '180 days';

insert into members 
values 
('C111','David Jackson','111 Pine St', '2026-07-10');

-- TASK 10 - List Employees with Their Branch Manager's Name and their branch details:

select 
e1.*,
b.manager_id,
e2.emp_name as manager
from employees as e1
join 
branch as b 
on b.branch_id= e1.branch_id
join 
employees as e2 
on b.manager_id= e2.emp_id;

-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold:

CREATE TABLE expensive_books AS
SELECT * FROM books
WHERE rental_price > 7.00;
select* from expensive_books;

-- Task 12: Retrieve the List of Books Not Yet Returned

SELECT * FROM issued_status as ist
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL;


-- ADVANCE SQL PROBLEMS 
-- TASK 13 : Identify Members with Overdue Books
-- Write a query to identify members who have overdue books (assume a 30-day return period).
-- Display the member's_id, member's name, book title, issue date, and days overdue.

select 
ist.issued_member_id,
m.member_id,
b.book_title,
ist.issued_date,
rs.return_date,
CURRENT_DATE - ist.issued_date as over_dues_days
from issued_status as ist 
join 
members as m 
on m.member_id=ist.issued_member_id
join 
books as b
on b.isbn=ist.issued_book_isbn
left join 
return_status as rs 
on rs.issued_id=ist.issued_id
where rs.return_date is null
AND
    (CURRENT_DATE - ist.issued_date) > 30
ORDER BY ist.issued_member_id;


-- Task 14: Update Book Status on Return
-- Write a query to update the status of books in the books table to "Yes" 
-- when they are returned (based on entries in the return_status table).
DROP PROCEDURE IF EXISTS add_return_records;

DELIMITER //
CREATE PROCEDURE add_return_records(
    IN p_return_id VARCHAR(10),
    IN p_issued_id VARCHAR(10)
)
BEGIN
    DECLARE v_isbn VARCHAR(50);
    DECLARE v_book_name VARCHAR(80);

    -- Inserting into return_status
    INSERT INTO return_status
    (
        return_id,
        issued_id,
        return_date
    )
    VALUES
    (
        p_return_id,
        p_issued_id,
        CURDATE()
    );

    -- Get ISBN and Book Name
    SELECT
        issued_book_isbn,
        issued_book_name
    INTO
        v_isbn,
        v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    -- Update book status
    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    -- Display message
    SELECT CONCAT('Thank you for returning the book: ', v_book_name) AS Message;

END //
DELIMITER ;

 call add_return_records();


-- Testing FUNCTION add_return_records

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

-- calling function 
CALL add_return_records('RS138', 'IS135');

-- calling function 
CALL add_return_records('RS148', 'IS140');


-- Task 15: Branch Performance Report
-- Create a query that generates a performance report for each branch, showing 
-- the number of books issued, the number of books returned, 
-- and the total revenue generated from book rentals.

CREATE TABLE branch_reports
AS
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) as number_book_issued,
    COUNT(rs.return_id) as number_of_book_return,
    SUM(bk.rental_price) as total_revenue
FROM issued_status as ist
JOIN 
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
JOIN 
books as bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY b.branch_id,
    b.manager_id;

SELECT * FROM branch_reports;

-- Task 16: CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members 
-- containing members who have issued at least one book in the last 4 years.

drop table active_members;
CREATE TABLE active_members
AS
SELECT * FROM members
WHERE member_id in (SELECT 
                        DISTINCT issued_member_id   
                    FROM issued_status
                    WHERE 
                        issued_date >= CURRENT_DATE - INTERVAL 4 YEAR
                    );

SELECT * FROM active_members;

-- Task 17: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. 
-- Display the employee name, number of books processed, and their branch.

SELECT 
   e.emp_name, b.branch_id,	b.manager_id,	b.branch_address,	b.contact_no,
    COUNT(ist.issued_id) as no_book_issued
FROM issued_status as ist
JOIN
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
GROUP BY    e.emp_name, b.branch_id,	b.manager_id,	b.branch_address,	b.contact_no ;


-- Task 18: Stored Procedure Objective: Create a stored procedure to manage the status of 
-- books in a library system. Description: Write a stored procedure that updates 
-- the status of a book in the library based on its issuance. 
-- The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 
-- The procedure should first check if the book is available (status = 'yes').
-- If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
-- If the book is not available (status = 'no'), the procedure should return an error 
-- message indicating that the book is currently not available.
DROP PROCEDURE issue_book;
select * from books ;
DELIMITER //
CREATE PROCEDURE issue_book(
IN p_issued_id VARCHAR(10), 
IN p_issued_member_id  VARCHAR(30), 
IN p_issued_book_isbn VARCHAR(30), 
IN p_issued_emp_id  VARCHAR(10)
)
begin 
DECLARE v_status varchar(10);

select status 
INTO 
v_status
from books
where isbn=p_issued_book_isbn;
if v_status='yes' then 
insert into issued_status (issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
values
( p_issued_id,p_issued_member_id, CURDATE() ,p_issued_book_isbn,p_issued_emp_id);
UPDATE books
            SET status = 'no'
        WHERE isbn = p_issued_book_isbn;
        -- Display message
    SELECT CONCAT('BOOK RECORDS ADDED SUCCESSFULLY:', p_issued_book_isbn) AS NEW_MESSAGE ;
else         
 SELECT CONCAT('SORRY TO INFORM YOU THAT TEH BOOK YOU REQUESTED IS NOT AVALIABLE:', p_issued_book_isbn) AS NEW_MESSAGE_again ;
 END IF;
END //
DELIMITER ;

call issue_book('IS155','C108','978-0-553-29698-2','E104');
