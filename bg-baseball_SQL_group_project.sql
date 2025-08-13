-- Lahman Baseball Database Exercise

-- Use SQL queries to find answers to the Initial Questions. If time permits, choose one (or more) of the Open-Ended Questions. Toward the end of the bootcamp, we will revisit this data if time allows to combine SQL, Excel Power Pivot, and/or Python to answer more of the Open-Ended Questions.

-- Initial Questions

-- 1. What range of years for baseball games played does the provided database cover?
-- Answer: 1871-2016

SELECT
	MIN(yearid) AS min_year
	,MAX(yearid) AS max_year
FROM batting;

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT
	name AS team
	,namefirst
	,namelast
	,MIN(height) AS height_inches
	,g_all AS games_played
FROM people
	INNER JOIN appearances USING (playerid)
	INNER JOIN teams USING (teamid)
GROUP BY g_all, name, namefirst, namelast
ORDER BY height_inches ASC
LIMIT 1;

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT
	namefirst
	,namelast
	,schoolname
	,SUM(salary::NUMERIC::MONEY) AS total_salary
FROM collegeplaying
	INNER JOIN people USING (playerid)
	INNER JOIN schools USING (schoolid)
	INNER JOIN salaries USING (playerid)
WHERE schoolname = 'Vanderbilt University'
GROUP BY namefirst, namelast, schoolname
ORDER BY total_salary DESC;

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

-- Grouping pased on position.
SELECT yearid
	,namefirst
	,namelast
	,pos
	,CASE
		WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
		WHEN pos IN ('P', 'C') THEN 'Battery'
	END AS position_group
FROM fielding
	INNER JOIN people USING (playerid);


-- My answer
SELECT yearid
	,CASE
		WHEN pos = 'OF' THEN 'Outfield'
    	WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
   		WHEN pos IN ('P', 'C') THEN 'Battery'
  	END AS position_group,
  SUM(po) AS total_putouts
FROM fielding
WHERE yearid = 2016
GROUP BY position_group, yearid;

-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

-- Query 1: Strikeouts per game
SELECT (yearid / 10) * 10 AS decade
    ,SUM(so) AS total_strikeouts
    ,SUM(g) AS total_games
    ,ROUND(SUM(so)::NUMERIC / SUM(g), 2) AS avg_so_per_game
FROM pitching
WHERE yearid BETWEEN 1920 AND 2016
GROUP BY decade
ORDER BY decade;

-- Query 2: Homeruns per game
SELECT (yearid / 10) * 10 AS decade
    ,SUM(hr) AS total_homeruns
    ,SUM(g) AS total_games
    ,ROUND(SUM(hr)::NUMERIC / SUM(g), 2) AS avg_hr_per_game
FROM batting
WHERE yearid BETWEEN 1920 AND 2016
GROUP BY decade
ORDER BY decade;


-- Using CTE to join queries.
WITH pitching_stats AS (
	SELECT
	(yearid / 10) * 10 AS decade,
	SUM(so) AS total_strikeouts, SUM(g) AS total_games,
	ROUND(SUM(so)::NUMERIC / SUM(g), 2) AS avg_so_per_game
FROM pitching
WHERE yearid BETWEEN 1920 AND 2016
GROUP BY decade
),
batting_stats AS (
	SELECT
	(yearid / 10) * 10 AS decade,
	SUM(hr) AS total_homeruns, SUM(g) AS total_games,
	ROUND(SUM(hr)::NUMERIC / SUM(g), 2) AS avg_hr_per_game
FROM batting
WHERE yearid BETWEEN 1920 AND 2016
GROUP BY decade
)
SELECT decade, avg_so_per_game, avg_hr_per_game
FROM pitching_stats
	INNER JOIN batting_stats USING (decade)
ORDER BY decade;


-- Strikeouts per game
SELECT (t.yearid / 10) * 10 AS decade
    ,SUM(p.so) AS total_strikeouts
    ,SUM(t.g)  AS total_games
    ,ROUND(SUM(p.so)::NUMERIC / SUM(t.g), 2) AS avg_so_per_game
FROM pitching AS p
	INNER JOIN teams AS t USING (yearid, teamid)
WHERE t.yearid BETWEEN 1920 AND 2016
GROUP BY decade
ORDER BY decade;

-- Homeruns per game
SELECT (t.yearid / 10) * 10 AS decade
	,SUM(b.hr) AS total_homeruns
	,SUM(t.g) AS total_games
	,ROUND(SUM(b.hr)::NUMERIC / SUM(t.g), 2) AS avg_hr_per_game
FROM batting AS b
	INNER JOIN teams AS t USING (yearid, teamid)
WHERE t.yearid BETWEEN 1920 AND 2016
GROUP BY decade
ORDER BY decade;


SELECT
    (t.yearid / 10) * 10 AS decade,
    ROUND(SUM(p.so)::NUMERIC / SUM(t.g), 2) AS avg_so_per_game,
    ROUND(SUM(b.hr)::NUMERIC / SUM(t.g), 2) AS avg_hr_per_game
FROM teams AS t
	INNER JOIN pitching AS p
		ON t.yearid = p.yearid
		AND t.teamid = p.teamid
	INNER JOIN batting AS b
		ON t.yearid = b.yearid
		AND t.teamid = b.teamid
WHERE t.yearid BETWEEN 1920 AND 2016
GROUP BY decade
ORDER BY decade;

-- 6. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.

SELECT namefirst
	,namelast
	,SUM(sb) AS total_sb
	,SUM(cs) AS total_cs
	,SUM(sb) + SUM(cs) AS sb_attempts
	,ROUND(((SUM(sb) * 1.0 / NULLIF(SUM(sb) + SUM(cs), 0)) * 100), 2) AS success_rate
FROM batting
	INNER JOIN people USING (playerid)
WHERE yearid = 2016
GROUP BY namefirst, namelast
	HAVING (SUM(sb) + SUM(cs)) >= 20
ORDER BY success_rate DESC;

-- 7. a. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series?

SELECT name
	,yearid
	,MAX(w) AS most_wins
FROM teams
WHERE wswin = 'N' AND yearid >= '1970'
GROUP BY name, yearid
ORDER BY most_wins DESC
LIMIT 1;

-- b. What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year.

SELECT name
	,yearid
	,MIN(w) AS least_wins
FROM teams
WHERE wswin = 'Y' AND yearid <> 1981
GROUP BY name, yearid
ORDER BY least_wins;

-- c. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

SELECT
	COUNT(DISTINCT yearid) AS years_top_team_won_ws
FROM (
SELECT teams.yearid
	,teams.teamid
	,teams.w
	,teams.wswin
FROM teams
	INNER JOIN (
SELECT yearid
	,MAX(w) AS most_wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
GROUP BY yearid
) most_w_and_wswin
	ON teams.yearid = most_w_and_wswin.yearid
	AND teams.w = most_w_and_wswin.most_wins
WHERE wswin = 'Y'
) AS top_w_ws_teams;



SELECT
	ROUND((COUNT(DISTINCT yearid) * 100.0 / 47), 2) AS years_top_team_won_ws
FROM (
SELECT teams.yearid
	,teams.teamid
	,teams.w
	,teams.wswin
FROM teams
	INNER JOIN (
SELECT yearid
	,MAX(w) AS most_wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
GROUP BY yearid
) most_w_and_wswin
	ON teams.yearid = most_w_and_wswin.yearid
	AND teams.w = most_w_and_wswin.most_wins
WHERE wswin = 'Y'
) AS top_w_ws_teams;

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

SELECT teams.name AS team_name
	,parks.park_name
	,ROUND(SUM(hg.attendance) / SUM(games), 0) AS avg_attend_per_game
	,SUM(hg.games) as total_games
FROM homegames AS hg
	INNER JOIN parks USING (park)
	INNER JOIN teams ON hg.team = teams.teamid AND hg.year = teams.yearid
WHERE hg.year = 2016
GROUP BY teams.name, parks.park_name
	HAVING SUM(hg.games) >= 10
ORDER BY avg_attend_per_game DESC
LIMIT 5;


SELECT teams.name AS team_name
	,parks.park_name
	,ROUND(SUM(hg.attendance) / SUM(games), 0) AS avg_attend_per_game
	,SUM(hg.games) as total_games
FROM homegames AS hg
	INNER JOIN parks USING (park)
	INNER JOIN teams ON hg.team = teams.teamid AND hg.year = teams.yearid
WHERE hg.year = 2016
GROUP BY teams.name, parks.park_name
	HAVING SUM(hg.games) >= 10
ORDER BY avg_attend_per_game ASC
LIMIT 5;

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- 3 queries with diff outputs --

-- My answer(Not correct)
SELECT p.namefirst
    ,p.namelast
    ,t.name AS teamname
    ,am.lgid
    ,am.yearid
FROM awardsmanagers AS am
	INNER JOIN people AS p USING (playerid)
	INNER JOIN managers AS m
  		ON am.playerid = m.playerid
 		AND am.yearid   = m.yearid
	INNER JOIN teams AS t
  		ON m.yearid = t.yearid
		AND m.teamid = t.teamid
 		AND m.lgid   = t.lgid
WHERE am.awardid = 'TSN Manager of the Year'
	AND am.playerid IN (
      SELECT playerid
      FROM awardsmanagers
      WHERE awardid = 'TSN Manager of the Year'
	  AND m.lgid = 'NL' OR m.lgid = 'AL'
      GROUP BY playerid
      HAVING COUNT(DISTINCT lgid) = 2)
ORDER BY p.namelast, am.yearid;

-- Answer w/help
SELECT DISTINCT ON (p.playerid)
    p.namefirst,
    p.namelast,
    t.name AS teamname
FROM awardsmanagers AS am
	JOIN people AS p USING (playerid)
	JOIN managers AS m ON am.playerid = m.playerid
		AND am.yearid = m.yearid
	JOIN teams AS t ON m.yearid = t.yearid
		AND m.teamid = t.teamid
		AND m.lgid = t.lgid
WHERE am.awardid = 'TSN Manager of the Year'
  AND am.playerid IN (
      SELECT playerid
      FROM awardsmanagers
      WHERE awardid = 'TSN Manager of the Year'
      GROUP BY playerid
      HAVING COUNT(DISTINCT lgid) = 2)
ORDER BY p.playerid, am.yearid;

-- Answer w/help
SELECT namefirst,
    namelast,
    name
FROM awardsmanagers
	INNER JOIN managers USING(playerid, yearid)
	INNER JOIN people USING(playerid)
	INNER JOIN teams USING(yearid, teamid)
WHERE awardid = 'TSN Manager of the Year'
	AND playerid IN (
        SELECT playerid
        FROM awardsmanagers
        WHERE awardid = 'TSN Manager of the Year'
        	AND lgid = 'NL'
        INTERSECT
        SELECT playerid
        FROM awardsmanagers
        WHERE awardid = 'TSN Manager of the Year'
        	AND lgid = 'AL')
GROUP BY namefirst, namelast, name
ORDER BY namefirst, namelast;


-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

SELECT p.namefirst AS first_name
	,p.namelast AS last_name
    ,MAX(b.hr) AS max_homeruns
FROM batting AS b
	INNER JOIN people AS p
		ON b.playerid = p.playerid
WHERE b.yearid = 2016
	AND b.hr > 0
    AND (p.finalgame::date - p.debut::date) * 10 >= 36525
GROUP BY p.namefirst, p.namelast
ORDER BY max_homeruns DESC;

-- Open-ended questions

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.
-- a. Does there appear to be any correlation between attendance at home games and number of wins?
-- b. Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?