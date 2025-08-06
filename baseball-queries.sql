

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
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
LIMIT 5;

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
	);

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
ORDER BY 
	max_homeruns DESC;
