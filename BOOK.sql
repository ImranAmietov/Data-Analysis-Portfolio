
CREATE TABLE book(
	book_id INT PRIMARY KEY AUTO_INCREMENT,
	title VARCHAR(50),
	author VARCHAR(30),
	amount DECIMAL(8,2),
	price INT);

INSERT INTO book (title, author, price, amount)
VALUES ('Белая гвардия', 'Булгаков М.А.','540.50', '5'), ('Идиот', 'Достоевский Ф.М.','460.00', '10'), ('Братья Карамазовы', 'Достоевский Ф.М.','799.01', '2');
SELECT * from book;

--Наприкінці року ціну кожної книги на складі перераховують – знижують її на 30%.
SELECT title, author, amount, ROUND((price*0.7),2) AS new_price FROM book

--Під час аналізу продажів книг з'ясувалося, що найбільшою популярністю користуються книги Михайла Булгакова, на другому місці книги Сергія Єсеніна. 
--Тому вирішили підняти ціну книг Булгакова на 10%, а ціну книг Єсеніна - на 5%.
SELECT author, title, 
	ROUND(IF(author='Булгаков М.А.', price*1.1,IF(author='Есенин', price*1.05,price)),2) AS new_price

--Автор, ціна та кількість усіх книг, ціна яких менша за 500 або більше 600, а вартість всіх примірників цих книг більша або дорівнює 5000.
SELECT author, price, amount FROM book
WHERE (price<500 OR price>600) and amount*price>=5000;

--Назва та авторка книг, ціни яких належать інтервалу від 540.50 до 800 (включаючи межі), а кількість або 2, або 3, або 5, або 7.
SELECT title, author, price FROM book
WHERE (price between 540.5 and 800) and amount in(2,3,5,7);
ORDER BY 2, 3

--Назва та автора тих книг, назва яких складається із двох і більше слів, а ініціали автора містять літеру «С».
SELECT title, author FROM book
WHERE title LIKE "_% %" AND (author LIKE "%_.C.%" OR LIKE "%C._.%")
ORDER BY title

--Кількість різних книг і кількість екземплярів книг кожного автора, що зберігаються на складі.
SELECT author AS '', COUNT(DISTINCT(amount)) AS 'Pізнi_книги', SUM(amount) AS 'кількість'
	FROM book
GROUP BY author;

--Прізвище та ініціали автора, мінімальна, максимальна та середня ціна книг кожного автора.
SELECT author, MIN(price) AS 'мінімальна_ціна', MAX(price) AS 'максимальна_ціна', AVG(price) AS 'середня_ціна'
	FROM book
GROUP BY author;

--Сумарна вартість книг S (ім'я стовпця Вартість), податок на додану вартість для отриманих сум (ім'я стовпця ПДВ), 
--який включений у вартість та становить 18% (k=18), а також вартість книг (Вартість_без_ПДВ) без нього.
SELECT author, SUM(price*amount) AS 'Вартість', ROUND(SUM(price*amount*0.18/(1+0.18)),2) AS 'ПДВ',
	  ROUND(SUM(price*amount)/1.18),2) AS 'Вартість_без_ПДВ'
	  FROM book
GROUP BY author;

--Вартість всіх екземплярів кожного автора без урахування книг «Ідіот» та «Біла гвардія» із сумарною вартістю книг (без урахування книг «Ідіот» та «Біла гвардія») понад 5000.
SELECT author, SUM(price*amount) as 'Сумарна_вартість' FROM book
WHERE author<>'Ідіот' OR author<>'Біла гвардія'
GROUP BY author
HAVING SUM(price*amount)>5000
ORDER BY 3 DESC;

--Aвтор, назва та ціна книг, ціни яких перевищують мінімальну ціну книги на складі не більше ніж на 150 у відсортованому за зростанням ціни.
SELECT author, title, price FROM book
WHERE ABS(price-(SELECT MIN(price) FROM book))<=150
ORDER BY price ASC;

--Автор, назва та ціна тих книг, кількість екземплярів яких у таблиці book не дублюється.
SELECT author, title, amount FROM book
WHERE amount in(SELECT amount FROM book GROUP BY amount HAVING COUNT(amount)=1);

--Aвтор, назва та ціна тих книг, ціна яких менша за найбільшу з мінімальних цін, обчислених для кожного автора.
SELECT author, title, amount FROM book
WHERE price<ANY(SELECT MIN(price) FROM book GROUP BY author);

--Кількість та яких екземплярів книг потрібно замовити постачальникам, щоб на складі стала однакова кількість екземплярів кожної книги, 
--що дорівнює значенню найбільшої кількості екземплярів однієї книги на складі.
SELECT author, title, ((SELECT MAX(amount) FROM book)-amount) AS 'Заказ' FROM book
WHERE amount not in(SELECT MAX(amount) FROM book);

--Відсоток вигоди
SELECT *, ROUND((price*amount)/(SELECT SUM(price*amount) FROM book),2)*100 AS 'Відсоток_вигоди' 
FROM book
ORDER BY Відсоток_вигоди DESC;
	  
--Занести з таблиці supply в таблицю book лише книжки, авторів яких немає у book.
INSERT INTO book(title, author, price, amount)
SELECT title, author, price, amount FROM supply
WHERE author not in(SELECT author FROM book);

--Коригування значення для покупця в стовпці буде таким чином, щоб воно не перевищувало кількість екземплярів книг, зазначених у стовпці amount.
--А ціну тих книг, що їх покупець не замовляв, знизив на 10%.
UPDATE book
SET buy=IF(BUY>amount, amount, buy),
    price=IF(buy=0, price*0.9, price);

--Для тих книг у таблиці book , які є в таблиці supply, не тільки збільшити їх кількість в таблиці book ( збільшити їх кількість на значення стовпця amount таблиці supply),
--але й перерахувати їхню ціну.
UPDATE book, supply
SET book.amount=book.amount+supply.amount,
    book.price=(book.price+supply.price)/2
WHERE book.author+supply.author AND book.title+supply.title;
	  
--Видалити з таблиці supply книги тих авторів, загальна кількість екземплярів книг яких у таблиці book перевищує 10.
DELETE FROM supply
WHERE author in(SELECT author FROM book HAVING SUM(amount)>10);

--Таблицю замовлення (ordering), ключає авторів та назви книг, кількість екземплярів яких у таблиці book менша за середню кількість екземплярів книг у таблиці book.
CREATE TABLE ordering AS
SELECT author, title, (SELECT ROUND(AVG(amount)) FROM book) as amount 
	FROM book
WHERE amount<(SELECT ROUND(AVG(amount)) FROM book);

--Знижка 5% на найбільшу кількість екземплярів книг
UPDATE boook AS b1
SET b1.price=b1.price*0.95
WHERE b1.amount=(SELECT MAX(b2.amount) FROM (SELECT * FROM book) AS b2); 
    	
--Всі книги зі складу передали в магазин 
--(Заніс із таблиці supply в таблицю book тільки ті книги, назви яких відсутні в таблиці book, при цьому кількість цих книг у таблиці supply обнулив).
-- Три варіанти рішення
1. INSERT INTO book (title, author, price)
SELECT title, author, price from supply 
where (title, author) not in (SELECT title, author from  book);
UPDATE book, supply SET
    book.amount = supply.amount,
    supply.amount = 0
WHERE book.title = supply.title AND book.amount IS NULL;
SELECT * FROM book;
SELECT * FROM supply;

2. CREATE TABLE delivery AS
SELECT title, author, price, amount FROM supply WHERE title NOT IN (SELECT title FROM book);
UPDATE supply SET supply.amount=IF(supply.title=ANY(SELECT title FROM book), supply.amount, 0);
INSERT INTO book (title, author, price, amount) 
       SELECT * FROM delivery; 
SELECT * FROM book;
SELECT * FROM supply;

3. INSERT INTO book (title, author, price, amount)
SELECT title, author, price, -1 AS amount from supply
WHERE title not in(select title
                   from book); 
UPDATE book, supply SET
    book.amount = supply.amount,
    supply.amount = 0
WHERE book.title = supply.title AND book.amount = -1;
SELECT * FROM book;
SELECT * from supply






