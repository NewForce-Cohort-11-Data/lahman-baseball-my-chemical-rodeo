-- 1. What range of years for baseball games played does the provided database cover?
SELECT 
	MIN(year) || '-' || MAX(year) AS range
FROM 
	homegames;

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
SELECT
	namefirst, 
	namelast,
	height,
	name,
	SUM(g_all) OVER() AS games
FROM 
	people
INNER JOIN
	appearances
	USING(playerid)
INNER JOIN
	teams
	USING(yearid)
WHERE 
	height = (
	SELECT MIN(height)
	FROM people
	)
	AND teams.teamid = appearances.teamid;


-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

WITH vandy_salaries AS (
	SELECT 
		playerid,
		SUM(salary) as total_salary
	FROM
		collegeplaying
	INNER JOIN
		salaries
		USING(playerid)
	WHERE 
		schoolid = 'vandy'
	GROUP BY
		playerid
)
SELECT 
	namelast || ',' || ' ' || namefirst AS player_name,
	total_salary
FROM
	people
INNER JOIN
	vandy_salaries
	USING(playerid)
ORDER BY total_salary DESC NULLS LAST;

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
WITH labels AS (
	SELECT
		playerid,
		CASE 
			WHEN pos = 'OF' THEN 'Outfield'
			WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
			WHEN pos IN ('P', 'C') THEN 'Battery'
		END AS position_label
	FROM
		fielding
)
SELECT 
	position_label,
	SUM(po) AS putout_total
FROM 
	fielding
INNER JOIN
	labels
	USING(playerid)
GROUP BY 
	position_label;

-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?
-- Both seem to be generally increasing over time, though homeruns decreased slightly 2000-2010.
SELECT
	(LEFT(yearid::text, 3)||'0')::integer AS decade,
	ROUND((SUM(so) / SUM(g)::numeric), 2) AS avg_strikeouts_per_game
FROM
	batting
WHERE yearid >= 1920
GROUP BY
	decade;

SELECT
	(LEFT(yearid::text, 3)||'0')::integer AS decade,
	ROUND((SUM(hr) / SUM(g)::numeric), 2) AS avg_homeruns_per_game
FROM
	batting
WHERE yearid >= 1920
GROUP BY
	decade;

-- 6. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.
WITH yearly_totals AS (
	SELECT 
		playerid,
		SUM(sb) AS total_stolen,
		SUM(cs) AS total_caught
	FROM 
		batting
	WHERE 
		yearid = '2016'
	GROUP BY 
		playerid
)
SELECT 
	playerid,
	ROUND((total_stolen / (total_stolen + total_caught)::numeric)*100, 2) AS stolen_success
FROM
	yearly_totals
WHERE 
	(total_stolen + total_caught) > 20
ORDER BY
	stolen_success DESC;

-- 7. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year.
-- 1981 player strike.
SELECT 
	MAX(w)
FROM 
	teams
WHERE 
	yearid BETWEEN 1970 AND 2016
	AND wswin = 'N';

SELECT 
	MIN(w)
FROM 
	teams
WHERE 
	yearid BETWEEN 1970 AND 2016
	AND wswin = 'Y'
	AND yearid != '1981';
	
-- How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? 
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
	
-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
WITH highest_five AS (
	SELECT 
		team,
		park,
		(SUM(attendance) / SUM(games)) AS avg_attendance
	FROM 
		homegames
	WHERE 
		year = 2016
	GROUP BY
		team, park
	HAVING 
		SUM(games) >= 10
	ORDER BY
		avg_attendance DESC
	LIMIT 5
)
SELECT
	teams.name,
	teams.park,
	avg_attendance
FROM
	teams
INNER JOIN
	highest_five
	On highest_five.team = teams.teamid
WHERE 
	yearid = 2016
ORDER BY
	avg_attendance DESC
LIMIT 5;

WITH highest_five AS (
	SELECT 
		team,
		park,
		(SUM(attendance) / SUM(games)) AS avg_attendance
	FROM 
		homegames
	WHERE 
		year = 2016
	GROUP BY
		team, park
	HAVING 
		SUM(games) >= 10
	ORDER BY
		avg_attendance 
	LIMIT 5
)
SELECT
	teams.name,
	teams.park,
	avg_attendance
FROM
	teams
INNER JOIN
	highest_five
	On highest_five.team = teams.teamid
WHERE 
	yearid = 2016
ORDER BY
	avg_attendance 
LIMIT 5;

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.
SELECT 
	namelast || ',' || ' ' || namefirst AS manager_name,
	name
FROM 
	awardsmanagers
INNER JOIN 
	managers
	USING(playerid, yearid)
INNER JOIN
	people
	USING(playerid)
INNER JOIN
	teams
	USING(yearid, teamid)
WHERE 
	awardid = 'TSN Manager of the Year'
	AND playerid IN(
		(SELECT 
			playerid
		FROM
			awardsmanagers
		WHERE 
			awardid = 'TSN Manager of the Year'
			AND lgid = 'NL')
		INTERSECT
		(SELECT 
			playerid
		FROM
			awardsmanagers
		WHERE 
			awardid = 'TSN Manager of the Year'
			AND lgid = 'AL')
	)
GROUP BY
	name, manager_name
ORDER BY
	manager_name;

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
WITH career_high AS (
	SELECT 
		playerid,
		MAX(hr) AS max_homeruns
	FROM 
		batting
	WHERE
		hr > 0
	GROUP BY
		playerid
)
SELECT 
	namelast || ',' || ' ' || namefirst AS player_name,
	max_homeruns
FROM 
	batting
INNER JOIN
	career_high
	ON hr = max_homeruns AND batting.playerid = career_high.playerid
INNER JOIN
	people
	ON batting.playerid = people.playerid
WHERE 
	yearid = 2016
	AND ((finalgame::date) - (debut::date))*10 > 36525
ORDER BY 
	max_homeruns DESC;