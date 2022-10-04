--DEFORESTATION DATA EXPLORATION USING SQL
--Start by creating my virtual table 'forestation'. this table will contain all columns I need for further use.

CREATE VIEW forestation
AS
SELECT --selected only unique columns, what I need, to avoid duplicated columns as in the case of country_name which cuts across all tables
    r.country_name,
    r.country_code,
    r.region,
    r.income_group,
    f.year,
    f.forest_area_sqkm,
    l.total_area_sq_mi,
    CASE --creating the column with forest area as a percentage of land area. Use of case statement clears off division by zero error
         WHEN l.total_area_sq_mi = 0 OR l.total_area_sq_mi IS NULL THEN 0
         ELSE ROUND((SUM(f.forest_area_sqkm) * 100/(SUM(l.total_area_sq_mi) * 2.59)):: numeric, 2)
         END AS  forest_as_percentage_of_land
FROM regions r
FULL JOIN forest_area f
ON r.country_code = f.country_code
FULL JOIN land_area l
ON f.country_code = l.country_code
AND f.year = l.year
GROUP BY 1,2,3,4,5,6,7
ORDER BY 5 DESC;

--PART 1  GLOBAL SITUATION
--Using my virtual table 'forestation' to answer the following questions:
--a) What was the total forest area (in sq km) of the world in 1990?
SELECT year, region, SUM(forest_area_sqkm) AS total_forest_area_sqkm
FROM forestation
WHERE region = 'World' AND year = '1990'
GROUP BY 1,2;

--b) What was the total forest area (in sq km) of the world in 1990?
SELECT year, region, SUM(forest_area_sqkm) AS total_forest_area_sqkm
FROM forestation
WHERE region = 'World' AND year = '2016'
GROUP BY 1,2;

--c) What was the change (in sq km) in the forest area of the world from 1990 to 2016?
--d) What was the percent change in forest area of the world between 1990 and 2016?
--Getting the difference and the percent difference from the two queries above using the WITH statement
WITH t1 AS
     (SELECT f.year, f.region, SUM(f.forest_area_sqkm) AS total_forest_area_1990
      FROM forestation f
      WHERE region = 'World' AND year = '1990'
      GROUP BY 1,2),
     t2 AS
     (SELECT f.year, f.region, SUM(f.forest_area_sqkm) AS total_forest_area_2016
      FROM forestation f
      WHERE region = 'World' AND year = '2016'
      GROUP BY 1,2)
--this query returns negative values depicting a negative change in the world's forest area from 1990 to 2016
SELECT t1.total_forest_area_1990, t2.total_forest_area_2016, (t2.total_forest_area_2016 - t1.total_forest_area_1990) AS change_in_world_forest_area,
       ROUND(((t2.total_forest_area_2016 - t1.total_forest_area_1990)*100/t1.total_forest_area_1990)::numeric, 2) AS percent_change
FROM t1
JOIN t2
ON t1.region = t2.region
GROUP BY 1,2;

--e) compare the amount of forest area lost between 1990 and 2016, to which country's total area in 2016 is it closest to?
WITH t1 AS
     (SELECT f.year, f.region, SUM(f.forest_area_sqkm) AS total_forest_area_1
      FROM forestation f
      WHERE region = 'World' AND year = '1990'
      GROUP BY 1,2),
     t2 AS
     (SELECT f.year, f.region, SUM(f.forest_area_sqkm) AS total_forest_area_2
      FROM forestation f
      WHERE region = 'World' AND year = '2016'
      GROUP BY 1,2)

SELECT f.year, f.country_name, SUM(f.total_area_sq_mi), SUM(f.total_area_sq_mi) * 2.59 AS total_area_sqkm
FROM forestation f
WHERE year = 2016
GROUP BY 1,2
HAVING SUM(f.total_area_sq_mi) * 2.59 <=
    (SELECT (t1.total_forest_area_1 - t2.total_forest_area_2) AS change_in_world_forest_area
    FROM t1 JOIN t2 ON t1.region = t2.region)
ORDER BY 4 DESC
LIMIT 1;

--PART 2  REGIONAL OUTLOOK
--Create a table that shows the Regions and their percent forest area (sum of forest area divided by sum of land area) in 1990 and 2016. (Note that 1 sq mi = 2.59 sq km)
--This code displays data for the coulumns; region, percent forest area for 1990, percent forest area for 2016, and percent change in forest area
--We can then answer specific questions or pull specific data by using the WHERE filter
-- the codes in the latter part of the regional outlook answer specific questions. comment or uncomment them to see results
WITH t1 AS
     (SELECT f.year, f.region, SUM(f.forest_area_sqkm) * 100/(SUM(f.total_area_sq_mi) * 2.59) AS percent_forest_area_1990
      FROM forestation f
      WHERE year = '1990'
      GROUP BY 1,2),
     t2 AS
     (SELECT f.year, f.region, SUM(f.forest_area_sqkm) * 100/(SUM(f.total_area_sq_mi) * 2.59) AS percent_forest_area_2016
      FROM forestation f
      WHERE year = '2016'
      GROUP BY 1,2)

SELECT t1.region, t1.percent_forest_area_1990, t2.percent_forest_area_2016, ROUND((t1.percent_forest_area_1990)::numeric, 2) AS rounded_percent_1990, ROUND((t2.percent_forest_area_2016)::numeric, 2) AS rounded_percent_2016, ROUND(((t2.percent_forest_area_2016 - t1.percent_forest_area_1990)*100/t1.percent_forest_area_1990)::numeric, 2) AS percent_change_in_forest_area
FROM t1
JOIN t2
ON t1.region = t2.region
--WHERE t1.region = 'World' --(filter for data on world)
GROUP BY 1,2,3
ORDER BY 2,3;
--ORDER BY 3 DESC LIMIT 1; --(highest percent forest area 2016)
--ORDER BY 3 ASC LIMIT 1; --(lowest percent forest area 2016)
--ORDER BY 2 DESC LIMIT 1; --(highest percent forest area 1990)
--ORDER BY 2 ASC LIMIT 1; --(lowest percent forest area 1990)
--ORDER BY 6 ASC;

--PART 3 COUNTRY-LEVEL DETAIL
--the code below privides country level data. to answer questions regarding countries, we can navigate or order by a column name and then set a limit for cases where top five countries are of interest to us.
WITH t1 AS
     (SELECT f.year, f.region, f.country_name, SUM(f.forest_area_sqkm) AS forest_area_1990, SUM(f.forest_area_sqkm) * 100/(SUM(f.total_area_sq_mi) * 2.59) AS percent_forest_area_1990
      FROM forestation f
      WHERE year = '1990'
      GROUP BY 1,2,3),
     t2 AS
     (SELECT f.year, f.region, f.country_name, SUM(f.forest_area_sqkm) AS forest_area_2016, SUM(f.forest_area_sqkm) * 100/(SUM(f.total_area_sq_mi) * 2.59) AS percent_forest_area_2016
      FROM forestation f
      WHERE year = '2016'
      GROUP BY 1,2,3)

SELECT f.region, t1.country_name, t1.forest_area_1990, t2.forest_area_2016, t1.percent_forest_area_1990, t2.percent_forest_area_2016, ROUND(((t2.percent_forest_area_2016 - t1.percent_forest_area_1990)*100/t1.percent_forest_area_1990)::numeric, 2) AS percent_change_in_forest_area, (t2.forest_area_2016 - t1.forest_area_1990) AS difference_forest_area
FROM t1
JOIN t2
ON t1.country_name = t2.country_name
JOIN forestation f
ON t2.region = f.region
--WHERE (t2.forest_area_2016 - t1.forest_area_1990) IS NOT NULL --(ORDER BY 8 DESC LIMIT 2; after the GROUP BY clause while removing ORDER BY 7,8 will return the top 2 countries with forestation increase from 1990 to 2016)
--*GROUP BY 1,2,3,4,5,6
--*HAVING  ROUND(((t2.percent_forest_area_2016 - t1.percent_forest_area_1990)*100/t1.percent_forest_area_1990)::numeric, 2) IS NOT NULL
--*ORDER BY 7 DESC LIMIT 1;
--uncommenting the query with * returns the country with the largest percent change in forestation
GROUP BY 1,2,3,4,5,6
ORDER BY 7,8;
--ORDER BY 8 ASC LIMIT 6; --returns top 5 Amount Decrease in Forest Area by Country including 'World', 1990 & 2016
--ORDER BY 7 ASC LIMIT 5; -- returns top 5 Percent Decrease in Forest Area by Country, 1990 & 2016

--finding quartiles
SELECT sub.country_name, sub.region, sub.forest_as_percentage_of_land, sub.quartiles,
       COUNT(sub.country_name) OVER (PARTITION BY sub.quartiles ORDER BY sub.quartiles) AS country_count
FROM
    (SELECT f.country_name, f.region, f.forest_as_percentage_of_land,
     CASE WHEN f.forest_as_percentage_of_land <=25 THEN '<25'
          WHEN f.forest_as_percentage_of_land BETWEEN 25 AND 50 THEN '25 - 50'
          WHEN f.forest_as_percentage_of_land BETWEEN 50 AND 75 THEN '50 - 75'
          ELSE '> 75' END AS quartiles
    FROM forestation f
    WHERE year = 2016 AND f.forest_as_percentage_of_land IS NOT NULL
    GROUP BY 1, 2, 3) AS sub
--WHERE sub.quartiles = '> 75' --Returns the top Quartile Countries
GROUP BY 1, 2, 3, 4
ORDER BY 5 DESC;

--How many countries had a percent forestation higher than the United States in 2016?
SELECT COUNT(f.country_name) AS country_count
FROM forestation f
WHERE year = 2016 AND f.forest_as_percentage_of_land >
    (SELECT f.forest_as_percentage_of_land
     FROM forestation f
     WHERE f.year = 2016 AND f.country_name = 'United States')
;
