-- *** RCB win bat_1st vs bowl_1st percentage
with total_win as (select m.toss_decide,
						   td.toss_name,
						  count(m.match_winner) as win_count
				   from matches m join toss_decision td on m.toss_decide=td.toss_id
				   where match_winner='2'
				   group by  m.toss_decide,td.toss_name),
total_matches as (select toss_decide,count(*) as total_matches
				 from matches
				 where (team_1='2' or team_2='2')
				 group by toss_decide)
select tw.*,
       tm.total_matches,
       (tw.win_count/tm.total_matches)*100 as win_percentage
from total_win tw join total_matches tm on tw.toss_decide=tm.toss_decide;


-- ***  RCB success percentage in Each Venue
with total_win_venue as (select m.venue_id,v.venue_name,count(*) as total_win
						  from matches m join venue v on m.venue_id=v.venue_id
                          join team t on t.team_id=m.match_winner
						  where t.team_name='Royal Challengers Bangalore'
						  group by m.venue_id,v.venue_name),
total_played_venue as (select venue_id,count(*) total_played_matches from matches 
					   where (team_1='2' or team_2='2')
					   group by venue_id)
select twv.*,
       tpv.total_played_matches,
       (twv.total_win/tpv.total_played_matches)*100 as win_percentage
from total_win_venue twv join total_played_venue tpv on twv.venue_id=tpv.venue_id
order by total_played_matches desc;

select m.match_winner as team_id,t.team_name,count(m.match_winner) match_win_count 
from matches m join venue v on m.venue_id=v.venue_id 
join team t on m.match_winner=t.team_id
where v.venue_name='M Chinnaswamy Stadium'
and (team_1='2' or team_2='2')
group by m.match_winner,t.team_name
order by match_win_count desc;

-- *** RCB home ground win vs loss against opposite Team 
with rs1 as (select m.*,
                    case when team_1='2' then team_1 else team_2 end as team_rcb,
					case when team_1='2' then team_2 else team_1 end as opposite_team,
                    v.venue_name
			from matches m join venue v on m.venue_id=v.venue_id
			join team t on m.match_winner=t.team_id
			where v.venue_name='M Chinnaswamy Stadium'
			and (team_1='2' or team_2='2')),
loss_count as (select rs1.opposite_team,t.team_name,count(rs1.match_winner)loss_count
from rs1 join team t on rs1.opposite_team=t.team_id
where match_winner<>'2'
group by rs1.opposite_team,t.team_name
order by loss_count desc),
win_count as (select rs1.opposite_team,count(rs1.match_winner) as win_count
from rs1 
group by rs1.opposite_team)
select lc.*,wc.win_count 
from loss_count lc join win_count wc on lc.opposite_team=wc.opposite_team;



-- *** average runs in powerplay of each team from last 5 years
with total_powrplay_runs as (select t.team_name,sum(runs_scored) as powerplay_runs
							from  ball_by_ball bb join batsman_scored bs on  bb.match_id=bs.match_id and bb.over_id=bs.over_id
													and bb.ball_id=bs.ball_id and bb.innings_no=bs.innings_no
							join team t on t.team_id=bb.team_batting
                            join matches m on m.match_id=bb.match_id
                            join season s on m.season_id=s.season_id
							where bb.over_id<=6 and s.season_year between '2012' and '2016'
							group by t.team_name),
total_matches as (select t.team_name,count(distinct m.match_id) as total_matches  
				 from matches m join team t on m.team_1=t.team_id or m.team_2=t.team_id
                 join season s on m.season_id=s.season_id
                 where s.season_year between '2012' and '2016'
				 group by t.team_name)
select  tpr.*,tm.total_matches,(tpr.powerplay_runs/tm.total_matches) as avg_poerplay_runs,
        dense_rank() over(order by (tpr.powerplay_runs/tm.total_matches) desc) as 'rank'
from total_powrplay_runs tpr join total_matches tm on tpr.team_name=tm.team_name  
order by avg_poerplay_runs desc;                

-- *** average runs in death over of each team from last 5 years
with total_death_over_runs as (select t.team_name,sum(runs_scored) as deathover_runs
							  from  ball_by_ball bb join batsman_scored bs on  bb.match_id=bs.match_id and bb.over_id=bs.over_id
												  and bb.ball_id=bs.ball_id and bb.innings_no=bs.innings_no
							  join team t on t.team_id=bb.team_batting
                              join matches m on m.match_id=bb.match_id
                              join season s on m.season_id=s.season_id
							  where bb.over_id>=16 
							  group by t.team_name),
total_matches as (select t.team_name,count(distinct m.match_id) as total_matches  
				 from matches m join team t on m.team_1=t.team_id or m.team_2=t.team_id
                 join season s on m.season_id=s.season_id
				 group by t.team_name)
select  tdor.*,tm.total_matches,(tdor.deathover_runs/tm.total_matches) as avg_deathover_runs,
        dense_rank() over(order by (tdor.deathover_runs/tm.total_matches) desc) as 'rank'
from total_death_over_runs tdor join total_matches tm on tdor.team_name=tm.team_name  
order by avg_deathover_runs desc;                

-- *** average runs conceeded in death over of each team from last 5 years
with total_deathover_runs as (select t.team_name,sum(runs_scored) as deathover_runs
							from  ball_by_ball bb join batsman_scored bs on  bb.match_id=bs.match_id and bb.over_id=bs.over_id
												  and bb.ball_id=bs.ball_id and bb.innings_no=bs.innings_no
							join team t on t.team_id=bb.team_bowling
                            join matches m on m.match_id=bb.match_id
                            join season s on m.season_id=s.season_id
							where bb.over_id>=16
							group by t.team_name),
total_matches as (select t.team_name,count(distinct m.match_id) as total_matches  
				 from matches m join team t on m.team_1=t.team_id or m.team_2=t.team_id
                 join season s on m.season_id=s.season_id
				 group by t.team_name)
select  tdr.*,tm.total_matches,(tdr.deathover_runs/tm.total_matches) as avg_deathover_runs_conceeded,
         dense_rank() over(order by (tdr.deathover_runs/tm.total_matches) ) as 'rank' 
from total_deathover_runs tdr join total_matches tm on tdr.team_name=tm.team_name  
order by 'rank'; 

-- *** average runs conceeded in powerplay of each team from last 5 years
               
with total_powrplay_runs as (select t.team_name,sum(runs_scored) as powerplay_runs
							from  ball_by_ball bb join batsman_scored bs on  bb.match_id=bs.match_id and bb.over_id=bs.over_id
													and bb.ball_id=bs.ball_id and bb.innings_no=bs.innings_no
							join team t on t.team_id=bb.team_bowling
                            join matches m on m.match_id=bb.match_id
                            join season s on m.season_id=s.season_id
							where bb.over_id<=6 and s.season_year between '2012' and '2016'
							group by t.team_name),
total_matches as (select t.team_name,count(distinct m.match_id) as total_matches  
				 from matches m join team t on m.team_1=t.team_id or m.team_2=t.team_id
                 join season s on m.season_id=s.season_id
                 where s.season_year between '2012' and '2016'
				 group by t.team_name)
select  tpr.*,tm.total_matches,(tpr.powerplay_runs/tm.total_matches) as avg_powerplay_runs_conceeded,
dense_rank() over(order by (tpr.powerplay_runs/tm.total_matches) desc) as 'rank'
from total_powrplay_runs tpr join total_matches tm on tpr.team_name=tm.team_name  
order by 'rank';                

-- *** average wickets taken in powerplay of each team from last 5 years
               
with total_powrplay_wicket as (select t.team_name,count(wt.player_out) as wicket_taken
							  from  ball_by_ball bb join wicket_taken wt on  bb.match_id=wt.match_id and bb.over_id=wt.over_id
													and bb.ball_id=wt.ball_id and bb.innings_no=wt.innings_no
							join team t on t.team_id=bb.team_bowling
                            join matches m on m.match_id=bb.match_id
                            join season s on m.season_id=s.season_id
							where bb.over_id<=6 and s.season_year between '2012' and '2016'
                            group by t.team_name),
total_matches as (select t.team_name,count(distinct m.match_id) as total_matches  
				 from matches m join team t on m.team_1=t.team_id or m.team_2=t.team_id
                 join season s on m.season_id=s.season_id
                 where s.season_year between '2012' and '2016'
				 group by t.team_name)
select  tpw.*,tm.total_matches,round((tpw.wicket_taken/tm.total_matches),1)as average_powerplay_wicket,
        dense_rank() over(order by (tpw.wicket_taken/tm.total_matches) desc) as 'rank'
from total_powrplay_wicket tpw join total_matches tm on tpw.team_name=tm.team_name
order by  average_powerplay_wicket desc;  





-- Each team total_wickets 
with rs as (select t.team_name,p.player_name,count(*) as total_wickets
			from player p join player_match pm on p.player_id=pm.player_id 
			join ball_by_ball bb on pm.match_id=bb.match_id and pm.player_id=bb.bowler
			join wicket_taken wt on bb.match_id=wt.match_id and bb.over_id=wt.over_id
								 and bb.innings_no=wt.innings_no and bb.ball_id=wt.ball_id
			join team t on t.team_id=bb.team_bowling
			group by t.team_name,p.player_name
			order by t.team_name,total_wickets desc)
select team_name,sum(total_wickets) as team_total_wickets
from rs group by team_name order by team_total_wickets desc; 

-- Top average batsman 
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
				   round(pr.total_runs/coalesce(po.number_of_times_out,1),1) as average_runs
			from player_runs pr left join player_out po on pr.player_id=po.player_id
            where pr.total_runs>3000
			order by average_runs desc limit 10;
            

-- toss win count by team
select t.team_id,t.team_name,count(*)
from team t join matches m on  t.team_id=m.toss_winner
group by t.team_id,t.team_name
order by count(*) desc;
-- toss win %
with toss_win as (select t.team_id,t.team_name,count(*) as toss_win_count
				  from team t join matches m on t.team_id=m.toss_winner
				  group by t.team_id,t.team_name),
match_played as (select t.team_id,t.team_name ,count(*) as played_matches 
				from team t join matches m on t.team_id=m.team_1 or t.team_id=m.team_2 
				where m.team_1<>m.team_2
				group by t.team_id,t.team_name)
select  tw.team_id,tw.team_name,(tw.toss_win_count/mp.played_matches)*100 as win_percentage
from toss_win tw join match_played mp on tw.team_id=mp.team_id
order by win_percentage desc;         
-- 1st bat win % and 2nd bat win % 

-- last 5 seasons man of the match count of each player
with rs1 as (select m.man_of_the_match,count(m.man_of_the_match)manofthe_match_count
			from matches m join player p on m.man_of_the_match=p.player_id
            where m.season_id in(9,8,7,6,5)
			group by man_of_the_match),
rs2 as (select p.player_id,p.player_name,t.team_id,t.team_name from player p 
		join player_match pm on p.player_id=pm.player_id
		join team t on pm.team_id=t.team_id)
select distinct rs2.player_id,
			    rs1.manofthe_match_count,
			    rs2.player_name
from rs1 join rs2 on rs1.man_of_the_match=rs2.player_id
order by manofthe_match_count desc limit 10;



-- top scorer 
select striker,p.player_name,sum(runs_scored)total_runs
from ball_by_ball bb join batsman_scored bs on bb.match_id=bs.match_id and bb.over_id=bs.over_id
                                            and bb.ball_id=bs.ball_id and bb.innings_no=bs.innings_no	
join player p on bb.striker=p.player_id
group by striker,p.player_name
order by total_runs desc
limit 10;

-- bowler total_runs_conceeded per over
with rs as (select bb.bowler,p.player_name,sum(bs.runs_scored) as total_runs_conceeded,
                  count(distinct bb.match_id,bb.over_id)total_over_bowled
			from ball_by_ball bb join batsman_scored bs on bb.match_id=bs.match_id 
                                 and bb.over_id=bs.over_id
								 and bb.ball_id=bs.ball_id and bb.innings_no=bs.innings_no
			join matches m on bs.match_id=m.match_id
			join player p on bb.bowler=p.player_id
			group by bb.bowler,p.player_name)
select distinct rs.*, total_runs_conceeded/total_over_bowled as economy
from rs join player_match pm on rs.bowler=pm.player_id
where total_over_bowled>50
order by economy desc;