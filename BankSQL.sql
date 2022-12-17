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
SELECT Accounts.Id, Accounts.Balance, SUM(CreditCards.Balance) AS CardsSum
FROM CreditCards
	RIGHT JOIN Accounts ON Accounts.Id = CreditCards.AccountId
GROUP BY Accounts.Id, Accounts.Balance
HAVING Accounts.Balance != SUM(CreditCards.Balance)

-- Задание 5
SELECT SocialStatuses.Title, COUNT(CreditCards.AccountId) AS CardsCount
FROM CreditCards
	JOIN Accounts ON Accounts.Id = CreditCards.AccountId
	JOIN Clients ON Clients.Id = Accounts.ClientId
	RIGHT JOIN SocialStatuses ON SocialStatuses.Id = Clients.SocialStatusId
GROUP BY SocialStatuses.Title

-- Задание 6
SELECT Accounts.Id, Accounts.Balance, Clients.FullName, SocialStatuses.Title
FROM Accounts
	LEFT JOIN Clients ON Clients.Id = Accounts.ClientId
	LEFT JOIN SocialStatuses ON SocialStatuses.Id = Clients.SocialStatusId
Where SocialStatuses.Id = 1

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
		PRINT CONCAT('No accounts with SocialStatusId = ', @SocialStatusId);
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
		PRINT CONCAT('Social status with id = ', @SocialStatusId, ' does not exist.');
END;
GO

EXEC AddMoneyToAccounts 1

SELECT Accounts.Id, Accounts.Balance, Clients.FullName, SocialStatuses.Title
FROM Accounts
	LEFT JOIN Clients ON Clients.Id = Accounts.ClientId
	LEFT JOIN SocialStatuses ON SocialStatuses.Id = Clients.SocialStatusId
Where SocialStatuses.Id = 1

-- Задание 7
SELECT Clients.FullName, COALESCE(SUM(Accounts.Balance), 0) - COALESCE(SUM(CreditCards.Balance), 0) AS Available
FROM Clients
	LEFT JOIN Accounts ON Accounts.ClientId = Clients.Id
	LEFT JOIN CreditCards ON CreditCards.AccountId = Accounts.Id
GROUP BY Clients.FullName