CREATE DATABASE BankDb
COLLATE Cyrillic_General_CI_AS;
GO

USE BankDb;

CREATE TABLE dbo.Banks
(
	Id INT IDENTITY PRIMARY KEY,
	Title NVARCHAR(50) NOT NULL CHECK(Title != '') UNIQUE,
)

CREATE TABLE dbo.Cities
(
	Id INT IDENTITY PRIMARY KEY,
	Title NVARCHAR(100) NOT NULL CHECK(Title != '') UNIQUE,
)

CREATE TABLE dbo.Branches
(
	Id INT IDENTITY PRIMARY KEY,
	BankId INT NOT NULL FOREIGN KEY REFERENCES dbo.Banks (Id) ON DELETE CASCADE,
	CityId INT NOT NULL FOREIGN KEY REFERENCES dbo.Cities (Id) ON DELETE CASCADE,
)

CREATE TABLE dbo.SocialStatuses
(
	Id INT IDENTITY PRIMARY KEY,
	Title NVARCHAR(50) NOT NULL CHECK(Title != '') UNIQUE,
)

CREATE TABLE dbo.Clients
(
	Id INT IDENTITY PRIMARY KEY,
	FullName NVARCHAR(50) NOT NULL CHECK(FullName != ''),
	SocialStatusId INT NOT NULL FOREIGN KEY REFERENCES dbo.SocialStatuses (Id) ON DELETE CASCADE,
)

CREATE TABLE dbo.Accounts
(
	Id INT IDENTITY PRIMARY KEY,
	Balance MONEY NOT NULL DEFAULT 0 CHECK(Balance >= 0),
	ClientId INT NOT NULL FOREIGN KEY REFERENCES dbo.Clients (Id) ON DELETE CASCADE,
	BankId INT NOT NULL FOREIGN KEY REFERENCES dbo.Banks (Id) ON DELETE CASCADE,
	CONSTRAINT UQ_Bank_Client UNIQUE (ClientID, BankId),
)

CREATE TABLE CreditCards
(
	Id INT IDENTITY PRIMARY KEY,
	Balance MONEY NOT NULL DEFAULT 0 CHECK(Balance >= 0),
	AccountId INT NOT NULL FOREIGN KEY REFERENCES dbo.Accounts (Id) ON DELETE CASCADE,
)

INSERT Cities
VALUES
('Минск'),
('Гомель'),
('Брест'),
('Могилёв'),
('Гродно')

INSERT Banks
VALUES
('Альфа Банк'),
('Беларусбанк'),
('Приорбанк'),
('БПС-Сбербанк'),
('Белагропромбанк')

INSERT Branches
VALUES
(1, 1),
(1, 1),
(2, 1),
(2, 2),
(3, 4)

INSERT SocialStatuses 
VALUES
('Трудоспособный'),
('Пенсионер'),
('Инвалид')

INSERT Clients
VALUES
('Александр', 1),
('Андрей', 2),
('Алексей', 3),
('Марина', 1),
('Екатерина', 1)

INSERT Accounts
VALUES
(DEFAULT, 1, 1),
(10, 1, 2),
(20, 2, 1),
(DEFAULT, 4, 1),
(1, 5, 3)

INSERT CreditCards
VALUES
(DEFAULT, 1),
(10, 2),
(DEFAULT, 3),
(DEFAULT, 3),
(DEFAULT, 4)

-- Задание 2
SELECT DISTINCT Banks.Title
FROM Banks
	JOIN Branches ON Banks.Id = Branches.BankId
	JOIN Cities ON Cities.Id = Branches.CityId
WHERE Cities.Title = 'Минск'

-- Задание 3
SELECT Clients.FullName, CreditCards.Balance, Banks.Title
FROM CreditCards
	JOIN Accounts ON Accounts.Id = CreditCards.Id
	JOIN Clients ON Clients.Id = Accounts.ClientId
	JOIN Banks ON Banks.Id = Accounts.BankId

-- Задание 4
SELECT Accounts.Id, Accounts.Balance AS AccountBalance, SUM(CreditCards.Balance) AS CardsSum
FROM CreditCards
	RIGHT JOIN Accounts ON Accounts.Id = CreditCards.AccountId
GROUP BY Accounts.Id, Accounts.Balance
HAVING Accounts.Balance != SUM(CreditCards.Balance)

-- Задание 5

-- GROUP BY
SELECT SocialStatuses.Title, COUNT(CreditCards.AccountId) AS CardsCount
FROM CreditCards
	JOIN Accounts ON Accounts.Id = CreditCards.AccountId
	JOIN Clients ON Clients.Id = Accounts.ClientId
	RIGHT JOIN SocialStatuses ON SocialStatuses.Id = Clients.SocialStatusId
GROUP BY SocialStatuses.Title

-- Подзапрос
SELECT DISTINCT SocialStatuses.Title,
	   COUNT(CreditCards.AccountId) OVER (PARTITION BY SocialStatuses.Title)
FROM CreditCards
	JOIN Accounts ON Accounts.Id = CreditCards.AccountId
	JOIN Clients ON Clients.Id = Accounts.ClientId
	RIGHT JOIN SocialStatuses ON SocialStatuses.Id = Clients.SocialStatusId

-- Задание 6
SELECT Accounts.Id, Accounts.Balance, Clients.FullName, SocialStatuses.Title
FROM Accounts
	LEFT JOIN Clients ON Clients.Id = Accounts.ClientId
	LEFT JOIN SocialStatuses ON SocialStatuses.Id = Clients.SocialStatusId
WHERE SocialStatuses.Id = 1

GO
CREATE PROCEDURE AddMoneyToAccounts
	@SocialStatusId INT
AS
BEGIN
	DECLARE @AccountsCount INT
	SELECT @AccountsCount = COUNT(Accounts.Id)
	FROM Accounts
		LEFT JOIN Clients ON Clients.Id = Accounts.ClientId
		LEFT JOIN SocialStatuses ON SocialStatuses.Id = Clients.SocialStatusId
	WHERE SocialStatusId = @SocialStatusId

	IF (@AccountsCount = 0)
		BEGIN
			DECLARE @Message varchar(100);
			SET @Message = CONCAT('No accounts with SocialStatusId = ', @SocialStatusId);
			THROW 50001, @Message, 1;
		END
	ELSE IF EXISTS (SELECT * FROM SocialStatuses WHERE Id = @SocialStatusId)
		BEGIN	
			UPDATE Accounts
			SET Balance = Balance + 10
			FROM
				(SELECT Accounts.Id 
				 FROM Accounts
					 LEFT JOIN Clients ON Clients.Id = Accounts.ClientId
					 LEFT JOIN SocialStatuses ON SocialStatuses.Id = Clients.SocialStatusId
				 WHERE SocialStatusId = @SocialStatusId) AS StatusAccount
			WHERE Accounts.Id = StatusAccount.Id
		END
	ELSE
		BEGIN
			SET @Message = CONCAT('Social status with id = ', @SocialStatusId, ' does not exist.');
			THROW 50001, @Message, 1;
		END
END;
GO

EXEC AddMoneyToAccounts 1

SELECT Accounts.Id, Accounts.Balance, Clients.FullName, SocialStatuses.Title
FROM Accounts
	LEFT JOIN Clients ON Clients.Id = Accounts.ClientId
	LEFT JOIN SocialStatuses ON SocialStatuses.Id = Clients.SocialStatusId
WHERE SocialStatuses.Id = 1

-- Задание 7
SELECT Clients.FullName, COALESCE(SUM(DISTINCT Accounts.Balance), 0) - COALESCE(SUM(CreditCards.Balance), 0) AS Available
FROM Clients
	LEFT JOIN Accounts ON Accounts.ClientId = Clients.Id
	LEFT JOIN CreditCards ON CreditCards.AccountId = Accounts.Id
GROUP BY Clients.FullName

-- Задание 8
SELECT Accounts.Id, Accounts.Balance AS AccountBalance, COALESCE(SUM(CreditCards.Balance), 0) AS CardsBalance
FROM Accounts
	LEFT JOIN CreditCards ON CreditCards.AccountId = Accounts.Id
	LEFT JOIN Clients ON Clients.Id = Accounts.ClientId
GROUP BY Accounts.Id, Accounts.Balance

GO
CREATE PROCEDURE TransferToCard
	@CardId INT,
	@Amount MONEY
AS
BEGIN
	IF NOT EXISTS (SELECT * FROM CreditCards WHERE Id = @CardId)
		BEGIN
			DECLARE @Message NVARCHAR(100);
			SET @Message = CONCAT('Credit card with id = ', @CardId, ' does not exist.');
			THROW 50001, @Message, 1;
		END

	DECLARE @Available MONEY
	SELECT @Available = Accounts.Balance - COALESCE(SUM(CreditCards.Balance), 0)
	FROM Accounts
		LEFT JOIN CreditCards ON CreditCards.AccountId = Accounts.Id
	GROUP BY Accounts.Id, Accounts.Balance
	HAVING Accounts.Id = (SELECT Accounts.Id
						  FROM Accounts
							  JOIN CreditCards ON CreditCards.AccountId = Accounts.Id
						  WHERE CreditCards.Id = @CardId)
	IF @Available = 0
		THROW 50001, 'No funds available', 1;
	ELSE IF @Amount > @Available
		BEGIN
			SET @Message = CONCAT('There are no funds in the account in the amount = ', @Amount);
			THROW 50001, @Message, 1;
		END
	ELSE
		BEGIN
			BEGIN TRY
				BEGIN TRANSACTION
					UPDATE CreditCards
					SET Balance = Balance + @Amount
					WHERE CreditCards.Id = @CardId
				COMMIT TRANSACTION
			END TRY

			BEGIN CATCH
				ROLLBACK TRANSACTION
				SELECT ERROR_NUMBER(), ERROR_MESSAGE()
				RETURN
			END CATCH
		END
END
GO

EXEC TransferToCard 1, 10

SELECT Accounts.Id, Accounts.Balance AS AccountBalance, COALESCE(SUM(CreditCards.Balance), 0) AS CardsBalance
FROM Accounts
	LEFT JOIN CreditCards ON CreditCards.AccountId = Accounts.Id
	LEFT JOIN Clients ON Clients.Id = Accounts.ClientId
GROUP BY Accounts.Id, Accounts.Balance

-- Задание 9
GO
CREATE TRIGGER Accounts_UPDATE
ON Accounts
FOR UPDATE
AS BEGIN
	DECLARE @AccountId INT
	SELECT @AccountId = inserted.Id
	FROM inserted

	DECLARE @newBalance MONEY
	SELECT @newBalance = inserted.Balance
	FROM inserted

	DECLARE @CardsBalance MONEY
	SELECT @CardsBalance = COALESCE(SUM(CreditCards.Balance), 0)
	FROM CreditCards
	Where @AccountId = CreditCards.AccountId

	IF @newBalance < @CardsBalance
		BEGIN
			PRINT 'Account balance cannot be less than cards balance'
			ROLLBACK TRANSACTION
		END
END

GO
CREATE TRIGGER CreditCards_INSERT_UPDATE
ON CreditCards
FOR INSERT, UPDATE
AS BEGIN
	DECLARE @AccountId INT
	SELECT @AccountId = inserted.AccountId
	FROM inserted

	DECLARE @AccountBalance MONEY
	SELECT @AccountBalance = Accounts.Balance
	FROM Accounts
	WHERE (Accounts.Id = @AccountId)

	DECLARE @newCardsSum MONEY
	SELECT @newCardsSum = SUM(CreditCards.Balance)
	FROM CreditCards
	WHERE (CreditCards.AccountId = @AccountId)

	IF @newCardsSum > @AccountBalance
		BEGIN
			PRINT 'Account balance cannot be less than cards balance'
			ROLLBACK TRANSACTION
		END
END


-- Тесты триггеров

SELECT Accounts.Balance AS AccountBalance, COALESCE(SUM(CreditCards.Balance), 0) AS CardsBalance
FROM Accounts
	LEFT JOIN CreditCards ON CreditCards.AccountId = Accounts.Id
GROUP BY Accounts.Id, Accounts.Balance

UPDATE Accounts
Set Balance = 30
Where Id = 2;

SELECT Accounts.Balance AS AccountBalance, COALESCE(SUM(CreditCards.Balance), 0) AS CardsBalance
FROM Accounts
	LEFT JOIN CreditCards ON CreditCards.AccountId = Accounts.Id
GROUP BY Accounts.Id, Accounts.Balance


SELECT Accounts.Balance AS AccountBalance, COALESCE(SUM(CreditCards.Balance), 0) AS CardsBalance
FROM Accounts
	LEFT JOIN CreditCards ON CreditCards.AccountId = Accounts.Id
GROUP BY Accounts.Id, Accounts.Balance

UPDATE CreditCards
Set Balance = 20
Where Id = 2;

SELECT Accounts.Balance AS AccountBalance, COALESCE(SUM(CreditCards.Balance), 0) AS CardsBalance
FROM Accounts
	LEFT JOIN CreditCards ON CreditCards.AccountId = Accounts.Id
GROUP BY Accounts.Id, Accounts.Balance


SELECT Accounts.Balance AS AccountBalance, COALESCE(SUM(CreditCards.Balance), 0) AS CardsBalance
FROM Accounts
	LEFT JOIN CreditCards ON CreditCards.AccountId = Accounts.Id
GROUP BY Accounts.Id, Accounts.Balance

INSERT CreditCards
VALUES
(10, 2)

SELECT Accounts.Balance AS AccountBalance, COALESCE(SUM(CreditCards.Balance), 0) AS CardsBalance
FROM Accounts
	LEFT JOIN CreditCards ON CreditCards.AccountId = Accounts.Id
GROUP BY Accounts.Id, Accounts.Balance
