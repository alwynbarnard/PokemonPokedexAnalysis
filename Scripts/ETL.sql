USE PokemonPokedex;

-- ##################################
-- Drop tables if they exist
-- ##################################

-- Drop Foreign Keys First
DECLARE @sql NVARCHAR(MAX) = '';
DECLARE @TableName NVARCHAR(128) = 'Pokemon';

SELECT @sql += 'ALTER TABLE ' + QUOTENAME(@TableName) + 
               ' DROP CONSTRAINT ' + QUOTENAME(fk.name) + ';' + CHAR(13)
FROM sys.foreign_keys fk
JOIN sys.tables t ON fk.parent_object_id = t.object_id
WHERE t.name = @TableName;

PRINT @sql;
EXEC sp_executesql @sql;

-- Drop Tables
IF EXISTS(SELECT * FROM sys.tables WHERE SCHEMA_NAME(schema_id) LIKE 'dbo' AND name like 'Ability')  
   DROP TABLE [dbo].[Ability];  
GO
IF EXISTS(SELECT * FROM sys.tables WHERE SCHEMA_NAME(schema_id) LIKE 'dbo' AND name like 'Classification')  
   DROP TABLE [dbo].[Classification];  
GO
IF EXISTS(SELECT * FROM sys.tables WHERE SCHEMA_NAME(schema_id) LIKE 'dbo' AND name like 'EggGroup')  
   DROP TABLE [dbo].[EggGroup];  
GO
IF EXISTS(SELECT * FROM sys.tables WHERE SCHEMA_NAME(schema_id) LIKE 'dbo' AND name like 'GameOfOrigin')  
   DROP TABLE [dbo].[GameOfOrigin];  
GO
IF EXISTS(SELECT * FROM sys.tables WHERE SCHEMA_NAME(schema_id) LIKE 'dbo' AND name like 'Pokemon')  
   DROP TABLE [dbo].[Pokemon];  
GO
IF EXISTS(SELECT * FROM sys.tables WHERE SCHEMA_NAME(schema_id) LIKE 'dbo' AND name like 'Types')  
   DROP TABLE [dbo].[Types];  
GO
IF EXISTS(SELECT * FROM sys.tables WHERE SCHEMA_NAME(schema_id) LIKE 'dbo' AND name like 'Pokemon')  
   DROP TABLE [dbo].[Pokemon];  
GO

-- ##################################
-- Extract Types from the RAW data
-- ##################################
CREATE TABLE Types (
	TypeId int NOT NULL UNIQUE,
	TypeName varchar(20) NOT NULL UNIQUE
);

INSERT INTO Types (TypeId, TypeName)
SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)), PrimaryType
FROM (SELECT DISTINCT PrimaryType FROM pokedex_raw) AS UniqueTypes;

ALTER TABLE Types
ADD CONSTRAINT PK_Types PRIMARY KEY (TypeId);

-- #################################################
-- Extract Classification Types from the RAW data
-- #################################################
CREATE TABLE Classification (
	ClassificationId int NOT NULL UNIQUE,
	ClassificationName varchar(50) NOT NULL UNIQUE
)
INSERT INTO Classification(ClassificationId, ClassificationName)
SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)), Classification
FROM (SELECT DISTINCT Classification FROM pokedex_raw) AS UniqueClass;

ALTER TABLE Classification
ADD CONSTRAINT PK_Classification PRIMARY KEY (ClassificationId);

-- #################################################
-- Extract Abilities from the RAW data
-- #################################################
CREATE TABLE Ability (
	AbilityId int NOT NULL UNIQUE,
	AbilityName varchar(50) NOT NULL UNIQUE,
	AbilityDescription varchar(300) NOT NULL
)
INSERT INTO Ability(AbilityId, AbilityName, AbilityDescription)
SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)), PrimaryAbility, PrimaryAbilityDescription
FROM (
	SELECT DISTINCT PrimaryAbility, PrimaryAbilityDescription FROM pokedex_raw WHERE PrimaryAbility IS NOT NULL
	UNION 
	SELECT DISTINCT SecondaryAbility, SecondaryAbilityDescription FROM pokedex_raw WHERE SecondaryAbility IS NOT NULL
	UNION 
	SELECT DISTINCT HiddenAbility, HiddenAbilityDescription FROM pokedex_raw WHERE HiddenAbility IS NOT NULL
	UNION
	SELECT DISTINCT SpecialEventAbility, SpecialEventAbilityDescription FROM pokedex_raw WHERE SpecialEventAbility IS NOT NULL
	) AS UniqueClass;

ALTER TABLE Ability
ADD CONSTRAINT PK_Ability PRIMARY KEY (AbilityId);

-- #################################################
-- Extract Games of Origin from the RAW data
-- #################################################
CREATE TABLE GameOfOrigin (
	GameId int NOT NULL UNIQUE,
	GameName varchar(30) NOT NULL UNIQUE
)
INSERT INTO GameOfOrigin(GameId, GameName)
SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)), GameofOrigin
FROM (SELECT DISTINCT GameofOrigin FROM pokedex_raw WHERE GameofOrigin IS NOT NULL) AS UniqueClass;

ALTER TABLE GameOfOrigin
ADD CONSTRAINT PK_GameOfOrigin PRIMARY KEY(GameId)

-- #################################################
-- Extract Egg Group Statistics from the RAW data
-- #################################################
CREATE TABLE EggGroup (
	EggGroupId int NOT NULL UNIQUE,
	EggGroupType varchar(30) NOT NULL UNIQUE
)
INSERT INTO EggGroup(EggGroupId, EggGroupType)
SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)), PrimaryEggGroup
FROM (
	SELECT DISTINCT PrimaryEggGroup FROM pokedex_raw WHERE PrimaryEggGroup IS NOT NULL
	UNION
	SELECT DISTINCT SecondaryEggGroup FROM pokedex_raw WHERE SecondaryEggGroup IS NOT NULL
	) AS UniqueClass;

ALTER TABLE EggGroup
ADD CONSTRAINT PK_EggGroup PRIMARY KEY(EggGroupId)

-- ##################################################################################################
-- Create the Main table that will be a collection of all of the Pokemon Pokedex data
-- ##################################################################################################
CREATE TABLE Pokemon (
	PokeDatabaseId int NOT NULL UNIQUE,
	PokemonId int NOT NULL,
	PokemonName varchar(50) NOT NULL,
	PokedexId int NOT NULL,
	ClassificationId int NOT NULL,
	AlternateFormName varchar(50),
	OriginalPokemonId int,
	LegendaryType varchar(20),
	PokemonHeight float NOT NULL,
	PokemonWeight float NOT NULL,
	PrimaryTypeId int NOT NULL,
	SecondaryTypeId int,
	PrimaryAbilityId int NOT NULL,
	SecondaryAbilityId int,
	HiddenAbilityId int,
	SpecialEventAbilityId int,
	MaleRatio float NOT NULL,
	FemaleRatio float NOT NULL,
	BaseHappiness int NOT NULL,
	GameOfOriginId int NOT NULL,
	PrimaryEggGroupId int NOT NULL,
	SecondaryEggGroupId int,
	EggCycleCount int NOT NULL,
	PreEvolutionPokemonId int,
	HealthStat int NOT NULL,
	AttackStat int NOT NULL,
	DefenseStat int NOT NULL,
	SpecialAttackStat int NOT NULL,
	SpecialDefenseStat int NOT NULL,
	SpeedStat int NOT NULL,
	BaseStatTotal int NOT NULL,
	HealthEV int NOT NULL,
	AttackEV int NOT NULL,
	DefenseEV int NOT NULL,
	SpecialAttackEV int NOT NULL,
	SpecialDefenseEV int NOT NULL,
	SpeedEV int NOT NULL,
	EVYieldTotal int NOT NULL,
	CatchRate int NOT NULL,
	ExperienceGrowth varchar(30) NOT NULL,
	ExperienceGrowthTotal int NOT NULL,
	EvolutionDetails varchar(300),
	PRIMARY KEY (PokeDatabaseId),
	CONSTRAINT FK_PrimaryAbility FOREIGN KEY (PrimaryAbilityId) REFERENCES Ability(AbilityId),
	CONSTRAINT FK_SecondaryAbility FOREIGN KEY (SecondaryAbilityId) REFERENCES Ability(AbilityId),
	CONSTRAINT FK_HiddenAbility FOREIGN KEY (HiddenAbilityId) REFERENCES Ability(AbilityId),
	CONSTRAINT FK_SpecialEventAbility FOREIGN KEY (SpecialEventAbilityId) REFERENCES Ability(AbilityId),
	CONSTRAINT FK_Classification FOREIGN KEY (ClassificationId) REFERENCES Classification(ClassificationId),
	CONSTRAINT FK_PrimaryType FOREIGN KEY (PrimaryTypeId) REFERENCES Types(TypeId),
	CONSTRAINT FK_SecondaryType FOREIGN KEY (SecondaryTypeId) REFERENCES Types(TypeId),
	CONSTRAINT FK_GameOfOrigin FOREIGN KEY (GameOfOriginId) REFERENCES GameOfOrigin(GameId),
	CONSTRAINT FK_PrimaryEggGroup FOREIGN KEY (PrimaryEggGroupId) REFERENCES EggGroup(EggGroupId),
	CONSTRAINT FK_SecondaryEggGroup FOREIGN KEY (SecondaryEggGroupId) REFERENCES EggGroup(EggGroupId),
)