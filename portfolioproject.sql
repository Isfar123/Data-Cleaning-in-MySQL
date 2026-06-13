SELECT * 
FROM layoffs; 

-- 1 remove duplicates
-- 2 standardize the data such as rectify the spelling mistakes
-- 3 Null values or blank values

-- Create a dummy table to copy all data from layoffs to that table as we also need the raw table in case of mistake
CREATE TABLE layoffs_staging
LIKE layoffs;

-- INSERT ALL DATA from layoffs to layoff_staging
SELECT *
FROM layoffs_staging;
INSERT layoffs_staging
SELECT *
FROM layoffs;

WITH duplicate_cte AS (
SELECT *,
ROW_NUMBER() over( 
partition by company,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) as row_num
from layoffs_staging
) 
SELECT *
FROM duplicate_cte
WHERE row_num>1;

SELECT *
FROM layoffs_staging
WHERE company='Casper';


-- create a temporary table to insert data to it
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
  
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;



-- Insert the data into layoffs_stagin2 table
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() over( 
partition by company,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) as row_num
from layoffs_staging;


SELECT *
FROM layoffs_staging2;

DELETE
FROM layoffs_staging2
WHERE row_num>1;

-- standardizing data( finding issues and fixing it)
SELECT company,TRIM(company)-- here i checked the trimming part before updating it
FROM layoffs_staging2;

UPDATE layoffs_staging2 -- updating the table and trimming the white spaces in the company column 
SET company=TRIM(company);

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%'; -- the industry = crypto has anomalies with name so replace all names with crypto

-- replace all crypto names with crypto
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
-- fix Unites States. issue using TRIM(TRAILING....)
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country )
WHERE country LIKE 'United States%';

-- convert date to suitable format
SELECT `date`,
str_to_date(`date`,'%m/%d/%Y')
FROM layoffs_staging2;

-- now update the date column to suitable format
UPDATE layoffs_staging2
SET `date`=str_to_date(`date`,'%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY column `date` DATE;

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- update industry column, set blank to NULL
UPDATE layoffs_staging2
SET industry=NULL 
WHERE industry = '';


SELECT t1.industry,t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
WHERE (t1.industry IS NULL or t1.industry= '') AND t2.industry IS NOT NULL;

update layoffs_staging2 t1
JOIN layoffs_staging2 t2 
ON t1.company=t2.company
WHERE (t1.industry IS NULL) AND (t2.industry IS NOT NULL);
