CREATE DATABASE BankDb;
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
(N'Минск'),
(N'Гомель'),
(N'Брест'),
(N'Могилёв'),
(N'Гродно')

INSERT Banks
VALUES
(N'Альфа Банк'),
(N'Беларусбанк'),
(N'Приорбанк'),
(N'БПС-Сбербанк'),
(N'Белагропромбанк')

INSERT Branches
VALUES
(1, 1),
(1, 1),
(2, 1),
(2, 2),
(3, 4)

INSERT SocialStatuses 
VALUES
(N'Трудоспособный'),
(N'Пенсионер'),
(N'Инвалид')

INSERT Clients
VALUES
(N'Александр', 1),
(N'Андрей', 2),
(N'Алексей', 3),
(N'Марина', 1),
(N'Екатерина', 1)

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