-- 6. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. 
-- (A stolen base attempt results either in a stolen base or being caught stealing.) 
-- Consider only players who attempted at least 20 stolen bases.


SELECT people.nameFirst, people.nameLast, batting.playerid, yearid, sb, cs, SUM(sb + cs) AS attempts, ROUND(((sb/(SUM(sb+cs)::numeric))*100), 2) AS percentage
FROM batting
JOIN people ON people.playerid = batting.playerid
WHERE yearid = 2016
GROUP BY people.nameFirst, people.nameLast, batting.playerid, yearid, sb, cs
HAVING SUM(sb+cs) >= 20
ORDER BY percentage DESC
LIMIT 1;

-- 7. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 

SELECT teamID, yearID, W, WSWin
FROM teams
WHERE yearID >= 1970 AND yearID <=2016 AND WSWin = 'N'
ORDER BY W DESC
LIMIT 1;

-- What is the smallest number of wins for a team that did win the world series?

SELECT teamID, yearID, W, WSWin
FROM teams
WHERE yearID >= 1970 AND yearID <=2016 AND WSWin = 'Y'
ORDER BY W
LIMIT 1;

-- Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. 
-- In 1981, there was a players' strike that halted the season and led to a split season.

-- Then redo your query, excluding the problem year. 

SELECT teamID, yearID, W, WSWin
FROM teams
WHERE yearID >= 1970 AND yearID <=2016 AND yearID <> 1981 AND WSWin = 'Y'
ORDER BY W
LIMIT 1;


-- How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? 

WITH max_per_year AS (
	SELECT
		yearid,
		MAX(w) max_wins
	FROM
		teams
	WHERE 
		yearid BETWEEN 1970 AND 2016
	GROUP BY
		yearid
	ORDER BY
		yearid
)
SELECT 
	COUNT(yearid)
FROM
	teams AS t
INNER JOIN
	max_per_year AS m
	USING(yearid)
WHERE 
	yearid BETWEEN 1970 AND 2016
	AND t.w = m.max_wins
	AND wswin = 'Y';


-- What percentage of the time?

WITH max_per_year AS (
	SELECT
		yearid,
		MAX(w) max_wins
	FROM
		teams
	WHERE 
		yearid BETWEEN 1970 AND 2016
	GROUP BY
		yearid
	ORDER BY
		yearid
)
SELECT 
	ROUND(((COUNT(yearid) / (2016-1970)::numeric)*100), 2) AS max_winner_percentage
FROM
	teams AS t
INNER JOIN
	max_per_year AS m
	USING(yearid)
WHERE 
	yearid BETWEEN 1970 AND 2016
	AND t.w = m.max_wins
	AND wswin = 'Y';