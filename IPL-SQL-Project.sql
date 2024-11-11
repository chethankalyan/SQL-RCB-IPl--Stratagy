use ipl;
-- 1) List the different dtypes of columns in table “ball_by_ball” (using information schema)

					select column_name,data_type
					from information_schema.columns
					where table_name='ball_by_ball';
                    
-- 2) What is the total number of run scored in 1st season by RCB (bonus : also include the extra runs using the extra runs table) 
				select sum(BS.Runs_Scored)+sum(ER.Extra_Runs) as Total_Runs_Scored
				from Matches M
				join Ball_by_Ball BB on M.Match_Id = BB.Match_Id 
				left join Team T on BB.Team_Batting = T.Team_Id
				left join Batsman_Scored BS on BB.Match_Id = BS.Match_Id
					                        and BB.Over_Id = BS.Over_Id
											and BB.Ball_Id = BS.Ball_Id
											and BB.innings_no=BS.innings_no
				left join Extra_Runs ER on BB.Match_Id = ER.Match_Id
					                    and BB.Over_Id = ER.Over_Id
										and BB.Ball_Id = ER.Ball_Id
					                    and BB.Innings_No = ER.Innings_No
				where T.Team_Name = 'Royal Challengers Bangalore'
				and M.Season_Id = 1;

-- 3)How many players were more than age of 25 during season 2
				select count(distinct p.player_id) as players_count
				from player p join player_match pm 
				  on p.player_id = pm.player_id 
				join matches m on pm.match_id = m.match_id
				join (select min(match_date) as first_match_date
					  from matches
					  where season_id = 2) first_match
				where m.season_id = 2
				and timestampdiff(year, p.dob, first_match.first_match_date) > 25;

-- 4)How many matches did RCB win in season 1 ? 

				select count(*) as Season1_RCB_WinCount
				from season s join matches m 
				on s.season_id=m.season_id 
				join team t on m.match_winner=t.team_id
				where s.season_id=1 
				and t.team_name='Royal Challengers Bangalore';
            
-- 5)List top 10 players according to their strike rate in last 4 seasons
 
				select P.Player_Id,P.Player_Name,Total_Runs,Balls_Faced,
					   round(Total_Runs / Balls_Faced * 100, 2) AS Strike_Rate
				from(select PM.Player_Id,
							sum(BS.Runs_Scored) as Total_Runs,
							count(BB.Ball_Id) as Balls_Faced
					 from Player_Match PM join Matches M on PM.Match_Id = M.Match_Id
					 join Batsman_Scored BS on M.Match_Id = BS.Match_Id
					 join Ball_by_Ball BB on M.Match_Id = BB.Match_Id
						and BS.Over_Id = BB.Over_Id
						and BS.Ball_Id = BB.Ball_Id
					 where M.Season_Id >= (select max(Season_Id) from Season)-4
					 group by PM.Player_Id) as PlayerStats
				join Player P on PlayerStats.Player_Id = P.Player_Id
				order by Strike_Rate desc
				limit 10;

--  6)What is the average runs scored by each batsman considering all the seasons?

			with player_runs as (select p.player_id,p.player_name,sum(bs.runs_scored) total_runs 
								from player p join player_match pm on p.player_id=pm.player_id 
								join ball_by_ball bb on pm.match_id=bb.match_id and pm.player_id=bb.striker 
								join batsman_scored bs on bb.match_id=bs.match_id and bb.over_id=bs.over_id
													   and bb.ball_id=bs.ball_id and bb.innings_no=bs.innings_no
								group by p.player_id,p.player_name
								order by total_runs desc),
			player_out as (select p.player_id,p.player_name,count(wt.player_out) as number_of_times_out
							from player p join wicket_taken wt on p.player_id=wt.player_out
							group by p.player_id,p.player_name)
			select pr.*,
				   po.number_of_times_out,
				   pr.total_runs/coalesce(po.number_of_times_out,1) as average_runs
			from player_runs pr left join player_out po on pr.player_id=po.player_id
			order by average_runs desc;

--  7)What are the average wickets taken by each bowler considering all the seasons?   

		with player_wickets as (select p.player_id,p.player_name,count(*) as total_wickets_taken
								from player p join player_match pm on p.player_id=pm.player_id 
								join ball_by_ball bb on pm.match_id=bb.match_id and p.player_id=bb.Bowler
								join wicket_taken wt on bb.match_id=wt.match_id and bb.over_id=wt.over_id
													 and bb.ball_id=wt.ball_id and bb.innings_no=wt.innings_no
								group by p.player_id,p.player_name),
		player_innings as (select p.player_id,count(distinct bb.match_id,bb.innings_no) as total_innings_played
						  from player p join player_match pm on p.player_id=pm.player_id 
						  join ball_by_ball bb on pm.match_id=bb.match_id and pm.player_id=bb.bowler
						  group by p.player_id)
		select pw.player_id,
               pw.player_name,
			   (pw.total_wickets_taken/pi.total_innings_played) as average_wickets
		from player_wickets pw join player_innings pi on pw.player_id=pi.player_id
		order by average_wickets desc; 
                            
                           
  -- 8) List all the players who have average runs scored greater than overall average and who have taken wickets greater than overall average
                         
 -- player with avg runs greater than overall average --                          
WITH PlayerRuns AS (SELECT p.Player_Id,p.Player_Name,
                         ROUND(SUM(bs.Runs_Scored) / COUNT(DISTINCT ball.Match_Id),2) AS Avg_Runs_Per_Match
                    FROM player p
				    LEFT JOIN ball_by_ball ball ON p.Player_Id = ball.Striker
				    LEFT JOIN batsman_scored bs ON bs.Match_Id = ball.Match_Id AND bs.Over_Id = ball.Over_Id AND bs.Ball_Id = ball.Ball_Id
				    GROUP BY p.Player_Id, p.Player_Name),
PlayerAvg as(select p.Player_Id,p.Player_Name, 
					sum(bs.Runs_Scored) as Total_Runs,
					count(distinct bs.Match_Id) as Innings_Played,  
					SUM(bs.Runs_Scored) / COUNT(DISTINCT ball.match_id,ball.innings_no) AS Average_Runs  
			from player p join ball_by_ball ball on ball.Striker = p.Player_Id  
			join batsman_scored bs on bs.Match_Id = ball.Match_Id 
			and bs.Over_Id = ball.Over_Id and bs.Ball_Id = ball.Ball_Id and bs.innings_no=ball.innings_no
			group by p.Player_Id ,p.Player_Name
			having count(distinct ball.match_id,ball.innings_no) > 0  
			order by Average_Runs desc)
select row_number() over(order by Average_Runs desc ) as'Rank', PlayerAvg.*
from  PlayerAvg
where Average_Runs>(SELECT AVG(Avg_Runs_Per_Match) AS Overall_Avg_Runs
					FROM PlayerRuns) ;          
				
-- players with avg wickets greater than overall avg wicket                  
                            
			with player_wickets as (select p.player_id,p.player_name,count(*) as wickets
									from player p join player_match pm on p.player_id=pm.player_id 
									join ball_by_ball bb on pm.match_id=bb.match_id and pm.player_id=bb.bowler
									join wicket_taken wt on bb.match_id=wt.match_id and bb.over_id=wt.over_id 
                                                         and bb.ball_id=wt.ball_id and bb.innings_no=wt.innings_no
									group by p.player_id,p.player_name
									order by count(*) desc),
			played_match as (select p.player_id,p.player_name,count(*) as matchs
							from player p join player_match pm on p.player_id=pm.player_id 
							group by p.player_id,p.player_name),
							avg_wickets as (select pw.player_id,pw.player_name,(pw.wickets/plm.matchs) as avg_wicket
							from player_wickets pw join played_match plm on pw.player_id=plm.player_id
							order by avg_wicket desc)
			select * from avg_wickets 
			where avg_wicket>(select avg(avg_wicket) from avg_wickets); -- 0.94058221 is the overall average
      
-- 9)Create a table rcb_record table that shows wins and losses of RCB in an individual venue.

		create table rcb_record 
		(venue_name varchar(100),
		 wins int,
		 losses int);
        insert into rcb_record (venue_name,wins,losses)
               (select v.venue_name,
			   count(case when m.match_winner=t.team_id then 1 end) as wins,
               count(case when m.match_winner<>t.team_id then 1 end) as losses
		from venue v join matches m on v.venue_id=m.venue_id 
		join team t on m.team_1=t.team_id or m.team_2=t.team_id 
		where t.team_name='Royal Challengers Bangalore'
		group by v.venue_name);
    select * from rcb_record;
    
-- 10)What is the impact of bowling style on wickets taken.

with bowling_skill_wicket as (select bs.bowling_skill,count(*)as total_wickets
							from player p join player_match pm on p.player_id=pm.player_id 
							join ball_by_ball bb on pm.match_id=bb.match_id and pm.player_id=bb.bowler
							join wicket_taken wt on bb.match_id=wt.match_id and bb.over_id=wt.over_id 
												 and bb.ball_id=wt.ball_id and bb.innings_no=wt.innings_no
							join bowling_style bs on p.bowling_skill=bs.bowling_id                     
							group by bs.bowling_skill
							order by total_wickets desc),
bowling_skill_ball as (select bs.bowling_skill,count(distinct bb.match_id,bb.innings_no,bb.over_id,bb.ball_id)as total_balls_bowled
						from player p join player_match pm on p.player_id=pm.player_id 
						join ball_by_ball bb on pm.match_id=bb.match_id and pm.player_id=bb.bowler
						join bowling_style bs on p.bowling_skill=bs.bowling_id                     
						group by bs.bowling_skill
						order by total_balls_bowled desc)
select bsw.bowling_skill,
       bsw.total_wickets,
	   bsb.total_balls_bowled,
       round((bsb.total_balls_bowled/bsw.total_wickets),1) as ballstaken_per_wicket
from bowling_skill_wicket bsw join bowling_skill_ball bsb on bsw.bowling_skill=bsb.bowling_skill
order by ballstaken_per_wicket;
            
-- 11)Write the sql query to provide a status of whether the performance of the team better than the previous year
--    performance on the basis of number of runs scored by the team in the season and number of wickets taken             
      
  with total_season_runs as (select t.team_name,s.season_year,sum(bs.runs_scored) as total_runs   -- total_runs_by_season
							from team t join matches m on t.team_id=m.team_1 or t.team_id=m.team_2
							join ball_by_ball bb on m.match_id=bb.match_id 
							join batsman_scored bs on bb.match_id=bs.match_id and bb.over_id=bs.over_id 
												   and bb.ball_id=bs.ball_id and bb.innings_no=bs.innings_no
							join season s on m.season_id=s.season_id 
							where t.team_name='Royal Challengers Bangalore'
							group by t.team_name,s.season_year
							order by s.season_year),
	total_season_wicket as (select s.season_year,count(*) as total_wickets   -- total_wickets_by_season
							from team t join matches m on t.team_id=m.team_1 or t.team_id=m.team_2
							join ball_by_ball bb on m.match_id=bb.match_id 
							join wicket_taken wt on bb.match_id=wt.match_id and bb.over_id=wt.over_id 
												   and bb.ball_id=wt.ball_id and bb.innings_no=wt.innings_no
							join season s on m.season_id=s.season_id 
							where t.team_name='Royal Challengers Bangalore'
							group by t.team_name,s.season_year
							order by s.season_year)
select tsr.team_name,tsr.season_year,tsr.total_runs,tsw.total_wickets
from total_season_runs tsr join total_season_wicket tsw on tsr.season_year=tsw.season_year;

  
-- 12)Can you derive more KPIs for the team strategy if possible?
 --  yes
-- refer SQL File 6***

-- 13) Using SQL, write a query to find out average wickets taken by each bowler in each venue. 
--     Also rank the gender according to the average value.
					with each_venue_BowlerWickets as (select bb.Bowler, p.Player_Name,v.venue_name,
													count(distinct bb.Match_Id, bb.Over_Id, bb.Ball_Id, bb.Innings_No) as Total_Wickets,
													count(distinct bb.Match_Id,bb.innings_no) as Matches_Played
													from player p join player_match pm on p.player_id=pm.player_id 
													join matches m on pm.match_id=m.match_id
													join ball_by_ball bb on m.match_id=bb.match_id and pm.player_id=bb.bowler
													join wicket_taken wt on bb.match_id=wt.match_id and bb.over_id=wt.over_id 
																		and bb.ball_id=wt.ball_id and bb.innings_no=wt.innings_no
													join venue v on m.venue_id=v.venue_id
													group by bb.Bowler, p.Player_Name,v.venue_name)
									select Bowler as Player_Id,Player_Name,venue_name,
										   round(Total_Wickets/Matches_Played,1) as Average_Wickets,
                                           dense_rank() over(order by round(Total_Wickets/Matches_Played,1) desc) as 'rank'
									from each_venue_BowlerWickets
									order by average_wickets desc,'rank' desc;
                                    
                                    
-- 14) Which of the given players have consistently performed well in past seasons? 
--    (will you use any visualisation to solve the problem                             

-- last 3 seasons most man_of_the_match award ***
		with rs1 as (select m.man_of_the_match,count(m.man_of_the_match)manofthe_match_count
					from matches m join player p on m.man_of_the_match=p.player_id
					where m.season_id in(9,8,7)
					group by man_of_the_match),
		rs2 as (select p.player_id,p.player_name,t.team_id,t.team_name from player p 
				join player_match pm on p.player_id=pm.player_id
				join team t on pm.team_id=t.team_id)
		select distinct rs2.player_id,
						rs1.manofthe_match_count,
						rs2.player_name
		from rs1 join rs2 on rs1.man_of_the_match=rs2.player_id
		order by manofthe_match_count desc;
       
-- players in the list of top 5 scorer in last 3 seasons ***
with player_match_runs as (select bb.match_id,bb.striker,sum(runs_scored) as total_runs
					      from ball_by_ball bb join batsman_scored bs on bb.Match_Id=bs.Match_Id and bb.Innings_No=bs.Innings_No
																and bb.Over_Id=bs.Over_Id and bb.Ball_Id=bs.Ball_Id 
							group by bb.match_id,bb.striker),
result as (select pmr.striker as player_id,s.season_year,
                                 sum(pmr.total_runs) runs_scored,
                                 dense_rank() over(partition by season_year order by sum(pmr.total_runs) desc) season_runs_rank
			from player_match_runs pmr join matches m on pmr.match_id=m.match_id
			join season s on m.season_id=s.season_id
			group by pmr.striker,s.season_year),
top_run_rank_player as (select * from result
						where season_runs_rank between 1 and 5 
						and season_year between 2014 and 2016
		                order by season_year,season_runs_rank)
select trp.player_id,p.player_name,count(trp.player_id)
from top_run_rank_player trp join player p on trp.player_id=p.player_id
group by trp.player_id,p.player_name
order by count(trp.player_id) desc; 

-- number of times bowlers in top 10 list from last 3 seasons
with player_match_wicket as (select bb.match_id,bb.bowler,count(distinct wt.match_id,wt.innings_no,wt.over_id,wt.ball_id) as total_wickets
					        from ball_by_ball bb join wicket_taken wt on bb.Match_Id=wt.Match_Id and bb.Innings_No=wt.Innings_No
																      and bb.Over_Id=wt.Over_Id and bb.Ball_Id=wt.Ball_Id 
							group by bb.match_id,bb.bowler),
result as (select pmw.bowler as player_id,s.season_year,
                                 sum(pmw.total_wickets) wickets_taken,
                                 dense_rank() over(partition by season_year order by sum(pmw.total_wickets) desc) season_wicket_rank
			from player_match_wicket pmw join matches m on pmw.match_id=m.match_id
			join season s on m.season_id=s.season_id
			group by pmw.bowler,s.season_year),
top_wicket_rank_player as (select * from result
						  where season_wicket_rank between 1 and 10
						  and season_year between 2012 and 2016
		                order by season_year,season_wicket_rank)
select twrp.player_id,p.player_name,count(twrp.player_id)
from top_wicket_rank_player twrp join player p on twrp.player_id=p.player_id
group by twrp.player_id,p.player_name
order by count(twrp.player_id) desc;   

-- 15) Are there players whose performance is more suited to specific venues or conditions? 
--    (how would you present this using charts?)

			-- top 3 players in each venue scored highest_runs
			with result as (select p.player_id,p.player_name,v.venue_name,sum(bs.runs_scored) as total_runs
							from player p join player_match pm on p.player_id=pm.player_id 
							join ball_by_ball bb on pm.match_id=bb.match_id and pm.Player_Id=bb.Striker
							join batsman_scored bs on bb.match_id=bs.match_id and bb.over_id=bs.over_id
												   and bb.ball_id=bs.ball_id and bb.innings_no=bs.innings_no
							join matches m on bs.match_id=m.match_id
							join venue v on m.Venue_Id=v.venue_id
							join season s on m.season_id=s.season_id
							join city c on v.city_id=c.city_id
							join country cc on c.country_Id=cc.country_id
							where cc.country_name='India'
							group by p.player_id,p.player_name,v.venue_name
							order by total_runs desc),
			rank_player as (select *,dense_rank() over(partition by venue_name order by total_runs desc) as top_rank
							from result)
			select * from rank_player
			where top_rank between 1 and 3
			order by top_rank,total_runs desc;

-- top 3 players in each venue  taken highest_wicket
with result as (select p.player_id,p.player_name,v.venue_name,
				count(distinct wt.match_id,wt.Innings_No,wt.Over_Id,wt.Ball_Id) as total_wickets
				from player p join player_match pm on p.player_id=pm.player_id 
				join ball_by_ball bb on pm.match_id=bb.match_id and pm.Player_Id=bb.Bowler
				join wicket_taken wt on bb.match_id=wt.match_id and bb.over_id=wt.over_id
									   and bb.ball_id=wt.ball_id and bb.innings_no=wt.innings_no
				join matches m on wt.match_id=m.match_id
				join venue v on m.Venue_Id=v.venue_id
                join season s on m.season_id=s.season_id
                join city c on v.city_id=c.city_id
                join country cc on c.country_Id=cc.country_id
                where cc.country_name='India'
				group by p.player_id,p.player_name,v.venue_name
				order by total_wickets desc),
rank_player as (select *,dense_rank() over(partition by venue_name order by total_wickets desc) as top_rank
                from result)
select * from rank_player
where top_rank between 1 and 3
order by top_rank,total_wickets desc;


