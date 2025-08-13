-- Open-ended questions

-- 11.    Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12.    In this question, you will explore the connection between number of wins and attendance.
--         Does there appear to be any correlation between attendance at home games and number of wins?
--         Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

-- 13.    It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

WITH lefties AS (
	SELECT 
		COUNT(DISTINCT playerid) as l_pitcher_count
	FROM 
		people
	INNER JOIN
		fielding
		USING(playerid)
	WHERE 
		throws = 'L'
		AND pos = 'P'
),
pitcher_total AS (
	SELECT 
		COUNT(DISTINCT playerid) as t_pitcher_count
	FROM 
		people
	INNER JOIN
		fielding
		USING(playerid)
	WHERE 
		pos = 'P'
),
cy_lefties AS (
	SELECT 
		COUNT(DISTINCT playerid) AS cl_count
	FROM 
		awardsplayers
	INNER JOIN
		fielding
		USING(playerid)
	INNER JOIN
		people
		USING(playerid)
	WHERE 
		pos = 'P'
		AND throws = 'L'
		AND awardid = 'Cy Young Award'
),
cy_total AS (
	SELECT 
		COUNT(DISTINCT playerid) AS ct_count
	FROM 
		awardsplayers
	WHERE 
		awardid = 'Cy Young Award'
),
hof_lefties AS (
	SELECT 
		COUNT(DISTINCT playerid) AS hof_lefty_pitcher_count
	FROM 
		halloffame
	INNER JOIN
		people
		USING(playerid)
	INNER JOIN
		fielding
		USING(playerid)
	WHERE 
		throws = 'L'
		AND pos = 'P'	
),
hof_pitchers AS (
	SELECT 
		COUNT(DISTINCT playerid) AS hof_pitcher_count
	FROM 
		halloffame
	INNER JOIN
		people
		USING(playerid)
	INNER JOIN
		fielding
		USING(playerid)
	WHERE 
		pos = 'P'
)
SELECT 
	ROUND((l_pitcher_count::numeric / t_pitcher_count)*100, 2) AS lefty_percentage_of_pitchers,
	ROUND((cl_count::numeric / ct_count)*100, 2) AS lefty_percentage_of_cy,
	ROUND((hof_lefty_pitcher_count::numeric / hof_pitcher_count)*100, 2) AS lefty_percentage_of_hof_pitchers
FROM 
	cy_lefties
CROSS JOIN 
	lefties
CROSS JOIN
	cy_total
CROSS JOIN
	pitcher_total
CROSS JOIN
	hof_lefties
CROSS JOIN
	hof_pitchers;




	
--BONUS
-- In these exercises, you'll explore a couple of other advanced features of PostgreSQL.

-- 1.    In this question, you'll get to practice correlated subqueries and learn about the LATERAL keyword. Note: This could be done using window functions, but we'll do it in a different way in order to revisit correlated subqueries and see another keyword - LATERAL.

-- a. First, write a query utilizing a correlated subquery to find the team with the most wins from each league in 2016.

-- If you need a hint, you can structure your query as follows:

-- b. One downside to using correlated subqueries is that you can only return exactly one row and one column. This means, for example that if we wanted to pull in not just the teamid but also the number of wins, we couldn't do so using just a single subquery. (Try it and see the error you get). Add another correlated subquery to your query on the previous part so that your result shows not just the teamid but also the number of wins by that team.

-- c. If you are interested in pulling in the top (or bottom) values by group, you can also use the DISTINCT ON expression (https://www.postgresql.org/docs/9.5/sql-select.html#SQL-DISTINCT). Rewrite your previous query into one which uses DISTINCT ON to return the top team by league in terms of number of wins in 2016. Your query should return the league, the teamid, and the number of wins.

-- d. If we want to pull in more than one column in our correlated subquery, another way to do it is to make use of the LATERAL keyword (https://www.postgresql.org/docs/9.4/queries-table-expressions.html#QUERIES-LATERAL). This allows you to write subqueries in FROM that make reference to columns from previous FROM items. This gives us the flexibility to pull in or calculate multiple columns or multiple rows (or both). Rewrite your previous query using the LATERAL keyword so that your result shows the teamid and number of wins for the team with the most wins from each league in 2016.

-- If you want a hint, you can structure your query as follows:

-- SELECT * FROM (SELECT DISTINCT lgid FROM teams WHERE yearid = 2016) AS leagues, LATERAL ( ) as top_teams;

-- e. Finally, another advantage of the LATERAL keyword over using correlated subqueries is that you return multiple result rows. (Try to return more than one row in your correlated subquery from above and see what type of error you get). Rewrite your query on the previous problem sot that it returns the top 3 teams from each league in term of number of wins. Show the teamid and number of wins.

-- 2.    Another advantage of lateral joins is for when you create calculated columns. In a regular query, when you create a calculated column, you cannot refer it it when you create other calculated columns. This is particularly useful if you want to reuse a calculated column multiple times. For example,

-- SELECT teamid, w, l, w + l AS total_games, w*100.0 / total_games AS winning_pct FROM teams WHERE yearid = 2016 ORDER BY winning_pct DESC;

-- results in the error that "total_games" does not exist. However, I can restructure this query using the LATERAL keyword.

-- SELECT teamid, w, l, total_games, w*100.0 / total_games AS winning_pct FROM teams t, LATERAL ( SELECT w + l AS total_games ) AS tg WHERE yearid = 2016 ORDER BY winning_pct DESC;

-- a. Write a query which, for each player in the player table, assembles their birthyear, birthmonth, and birthday into a single column called birthdate which is of the date type.

-- b. Use your previous result inside a subquery using LATERAL to calculate for each player their age at debut and age at retirement. (Hint: It might be useful to check out the PostgreSQL date and time functions https://www.postgresql.org/docs/8.4/functions-datetime.html).

-- c. Who is the youngest player to ever play in the major leagues?

-- d. Who is the oldest player to player in the major leagues? You'll likely have a lot of null values resulting in your age at retirement calculation. Check out the documentation on sorting rows here https://www.postgresql.org/docs/8.3/queries-order.html about how you can change how null values are sorted.

-- 3.    For this question, you will want to make use of RECURSIVE CTEs (see https://www.postgresql.org/docs/13/queries-with.html). The RECURSIVE keyword allows a CTE to refer to its own output. Recursive CTEs are useful for navigating network datasets such as social networks, logistics networks, or employee hierarchies (who manages who and who manages that person). To see an example of the last item, see this tutorial: https://www.postgresqltutorial.com/postgresql-recursive-query/. In the next couple of weeks, you'll see how the graph database Neo4j can easily work with such datasets, but for now we'll see how the RECURSIVE keyword can pull it off (in a much less efficient manner) in PostgreSQL. (Hint: You might find it useful to look at this blog post when attempting to answer the following questions: https://data36.com/kevin-bacon-game-recursive-sql/.)

-- a. Willie Mays holds the record of the most All Star Game starts with 18. How many players started in an All Star Game with Willie Mays? (A player started an All Star Game if they appear in the allstarfull table with a non-null startingpos value).

-- b. How many players didn't start in an All Star Game with Willie Mays but started an All Star Game with another player who started an All Star Game with Willie Mays? For example, Graig Nettles never started an All Star Game with Willie Mayes, but he did star the 1975 All Star Game with Blue Vida who started the 1971 All Star Game with Willie Mays.

-- c. We'll call two players connected if they both started in the same All Star Game. Using this, we can find chains of players. For example, one chain from Carlton Fisk to Willie Mays is as follows: Carlton Fisk started in the 1973 All Star Game with Rod Carew who started in the 1972 All Star Game with Willie Mays. Find a chain of All Star starters connecting Babe Ruth to Willie Mays.

-- d. How large a chain do you need to connect Derek Jeter to Willie Mays?
