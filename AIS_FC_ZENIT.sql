CREATE TABLE Zenit_players (
    player_id SERIAL PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    age INT,
    position VARCHAR(20)
);
select match_participation_id, first_name, last_name, match_date, number_of_game_minutes,
number_of_goals,number_of_assistants,having_a_red_card,having_a_yellow_card
from Zenit_players JOIN match_participation
ON (Zenit_players.player_id = match_participation.player_id) JOIN match ON (match_participation.match_id = match.match_id);

CREATE TABLE match_participation (
    match_participation_id SERIAL PRIMARY KEY,
    player_id INT REFERENCES Zenit_players(player_id),
    match_id INT REFERENCES match(match_id),
    number_of_game_minutes INT,
    number_of_goals INT,
    number_of_assistants INT,
    having_a_red_card BOOLEAN,
    having_a_yellow_card BOOLEAN
);
select * from match_participation;
insert into match_participation (player_id, number_of_game_minutes, number_of_goals, number_of_assistants, having_a_red_card, having_a_yellow_card)
values (8,60, 6,6,true, false);

insert into match_participation (player_id, match_id,number_of_goals)
values (4,7,4);

CREATE OR REPLACE FUNCTION check_consecutive_player_match()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM match_participation
        WHERE player_id = NEW.player_id
        AND match_id = NEW.match_id
        AND match_participation_id <> NEW.match_participation_id
        ORDER BY match_participation_id DESC LIMIT 1
    ) THEN
        RAISE EXCEPTION 'данный игрок уже участвует в матче!';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_consecutive_player_match
BEFORE INSERT OR UPDATE ON match_participation
FOR EACH ROW
EXECUTE FUNCTION check_consecutive_player_match();



-- запросы для пользователя
-- новости мата
SELECT home_team.club_name, away_team.club_name, match_date, score, comment FROM match JOIN match_news ON match.match_id = match_news.match_id JOIN clubs AS home_team ON match.home_team_id = home_team.club_id JOIN clubs AS away_team ON match.away_team_id = away_team.club_id;
-- 2
select first_name, last_name, match_date, number_of_game_minutes, number_of_goals,number_of_assistants,having_a_red_card,having_a_yellow_card from Zenit_players JOIN match_participation ON (Zenit_players.player_id = match_participation.player_id) JOIN match ON (match_participation.match_id = match.match_id);
-- 3 (как играют соперники Zenit)
SELECT home_team.club_name, away_team.club_name, match_date, score
FROM match
JOIN clubs AS home_team ON match.home_team_id = home_team.club_id
JOIN clubs AS away_team ON match.away_team_id = away_team.club_id
where away_team.club_id != '1' and home_team.club_id != '1' order by match_date;
-- 4 состав Zenit
select last_name, first_name, age, position from Zenit_players;
-- 5	Формирование таблицы турнира (какое место занимает ZENIT после каждого тура ищем ID и смотрим место которое занял ЦСКА после каждого сыгранного матча)
select home_team.club_name, away_team.club_name, score, name_of_tournament, match_date, place
from match
JOIN clubs AS home_team ON match.home_team_id = home_team.club_id
JOIN clubs AS away_team ON match.away_team_id = away_team.club_id
JOIN tournament on match.tournament_id = tournament.tournament_id
where (away_team.club_id = '1' or home_team.club_id = '1')
and tournament.place is not NULL
order by match_date;
-- 6	Формирование сетки турнира (рисуем таблицу с учетом 1/8 ¼ ½ 1/1 все матчи заполним)
select home_team.club_name, away_team.club_name, score, name_of_tournament, match_date, tournament_stage
from match
JOIN clubs AS home_team ON match.home_team_id = home_team.club_id
JOIN clubs AS away_team ON match.away_team_id = away_team.club_id
JOIN tournament t on match.tournament_id = t.tournament_id
where t.tournament_stage is not NULL
order by tournament_stage;


CREATE TABLE match (
    match_id SERIAL PRIMARY KEY,
    home_team_id INT REFERENCES clubs(club_id),
    away_team_id INT REFERENCES clubs(club_id),
    tournament_id INT REFERENCES tournament(tournament_id),
    match_date DATE,
    score VARCHAR(10),
    name_of_tournament VARCHAR(30)
);

SELECT t.place, t.number_of_points, t.tournament_stage, m.name_of_tournament
FROM tournament t
JOIN match m ON t.tournament_id = m.tournament_id;

CREATE TABLE tournament (
    tournament_id SERIAL PRIMARY KEY,
    place INT,
    number_of_points INT,
    tournament_stage VARCHAR(20)
    CONSTRAINT chk_tournament CHECK (
        (tournament_stage IS NULL AND number_of_points IS NULL AND place IS NULL) OR
         (place IS NOT NULL AND number_of_points IS NOT NULL AND tournament_stage IS NULL) OR
         (place IS NULL AND number_of_points IS NULL AND tournament_stage IS NOT NULL))
);


CREATE TABLE clubs (
    club_id SERIAL PRIMARY KEY,
    club_name VARCHAR(40),
    country_name VARCHAR(40)
);
select score, match_date
from match
join clubs as home_team on home_team.club_id = match.home_team_id
join clubs as away_team on away_team.club_id = match.away_team_id
join tournament on match.tournament_id = tournament.tournament_id
where name_of_tournament ='Russian Premier League'
order by match_date;

SELECT home_team.club_name, away_team.club_name, match.score
                          FROM match
                          JOIN clubs AS home_team ON home_team.club_id = match.home_team_id
                          JOIN clubs AS away_team ON away_team.club_id = match.away_team_id
                          JOIN tournament ON match.tournament_id = tournament.tournament_id
                          WHERE name_of_tournament = 'Russian Premier League'
                          order by match_date;

insert into match (home_team_id, away_team_id, tournament_id, score, name_of_tournament, match_date)
values (1,13,1,'2:0','Russian Premier League', '2023-05-19');

select club_name from clubs where club_id = '13';



DELETE FROM match
WHERE name_of_tournament = 'Russian Premier League'
AND match_date IS NULL;


select home_team.club_name, away_team.club_name
from match
join clubs as home_team on home_team.club_id = match.home_team_id
join clubs as away_team on away_team.club_id = match.away_team_id
join tournament on match.tournament_id = tournament.tournament_id
where name_of_tournament ='Russian Premier League';

SELECT DISTINCT club_name
FROM (
  SELECT home_team.club_name
  FROM match
  JOIN clubs AS home_team ON home_team.club_id = match.home_team_id
  JOIN tournament ON match.tournament_id = tournament.tournament_id
  WHERE name_of_tournament = 'Russian Premier League'
  UNION
  SELECT away_team.club_name
  FROM match
  JOIN clubs AS away_team ON away_team.club_id = match.away_team_id
  JOIN tournament ON match.tournament_id = tournament.tournament_id
  WHERE name_of_tournament = 'Russian Premier League'
) AS all_teams;


SELECT COUNT(DISTINCT club_name) AS number_of_teams
FROM (
  SELECT home_team.club_name FROM match
  JOIN clubs AS home_team ON home_team.club_id = match.home_team_id
  JOIN tournament ON match.tournament_id = tournament.tournament_id
  WHERE name_of_tournament = 'Russian Premier League'

  UNION

  SELECT away_team.club_name FROM match
  JOIN clubs AS away_team ON away_team.club_id = match.away_team_id
  JOIN tournament ON match.tournament_id = tournament.tournament_id
  WHERE name_of_tournament = 'Russian Premier League'
) AS all_teams;


-- select match_id, home_team.club_name, away_team_id.club_name, match_date, score, name_of_tournament, place, tournament_stage
-- from match JOIN tournament
-- ON (match.tournament_id = tournament.tournament_id) JOIN clubs ON (clubs.club_id = match.club_id);

SELECT match_id, home_team.club_name, away_team.club_name, match_date, score, name_of_tournament, place, tournament_stage
FROM match
JOIN tournament ON match.tournament_id = tournament.tournament_id
JOIN clubs AS home_team ON match.home_team_id = home_team.club_id
JOIN clubs AS away_team ON match.away_team_id = away_team.club_id;

select comment, match.match_date
from match_news
join match as match on match_news.match_id = match.match_id
where match.match_date = '2023-04-01';

SELECT match_news_id, match_date, comment FROM match JOIN match_news ON match.match_id = match_news.match_id where match.match_date = '2023-04-29';



SELECT match_news_id, match_date, comment FROM match JOIN match_news ON match.match_id = match_news.match_id;

CREATE TABLE match_news (
    match_news_id SERIAL PRIMARY KEY,
    match_id INT REFERENCES match(match_id),
    comment VARCHAR(200)
);


-- drop table Zenit_players CASCADE;
-- drop table tournament CASCADE;
-- drop table clubs CASCADE;
-- drop table match CASCADE;
-- drop table match_participation CASCADE;
-- drop table match_news CASCADE;

INSERT INTO Zenit_players (last_name, first_name, age, position)
VALUES  ('Акинфеев', 'Игорь', 35, 'Вратарь'),
        ('Селихов', 'Илья', 26, 'Защитник'),
        ('Сантос', 'Карл', 28, 'Защитник'),
        ('Жирков', 'Василий', 35, 'Защитник'),
        ('Халков', 'Халк', 34, 'Полузащитник'),
        ('Роналду', 'Криштиану', 36, 'Нападающий'),
        ('Месси', 'Лионель', 44, 'Нападающий'),
        ('Кузяев', 'Далер', 26, 'Полузащитник'),
        ('Влашич', 'Никола', 24, 'Полузащитник'),
        ('Миранчук', 'Антон', 30, 'Полузащитник'),
        ('Кучаев', 'Константин', 23, 'Полузащитник'),
        ('Mancini', 'Roberto', 27, 'Защитник'),
        ('Roberto', 'Sergi', 24, 'Нападающий'),
        ('Фернандес', 'Жозе', 30, 'Защитник'),
        ('Винисиус', 'Джуниор', 32, 'Защитник');

INSERT INTO clubs (club_name, country_name)
VALUES  ('ЦСКА', 'Россия'),
        ('Урал', 'Россия'),
        ('Нижний Новгород', 'Россия'),
        ('Крылья Советов', 'Россия'),
        ('Real Madrid', 'Spain'),
        ('Barcelona', 'Spain'),
        ('Manchester United', 'England'),
        ('Зенит', 'Россия'),
        ('Краснодар', 'Россия'),
        ('Рубин', 'Россия'),
        ('Ростов', 'Россия'),
        ('Арсенал', 'Россия'),
        ('Ахмат', 'Россия'),
        ('Уфа', 'Россия'),
        ('Химки', 'Россия'),
        ('Тамбов', 'Россия'),
        ('Club America', 'Mexico');

INSERT INTO tournament (place, number_of_points, tournament_stage) VALUES
    (1, 12, NULL),
    (2, 9, NULL),
    (3, 6, NULL),
    (4, 3, NULL),
    (NULL, NULL, 'Round of 16');

INSERT INTO tournament (place, number_of_points, tournament_stage) VALUES
    (4, 12, NULL),
    (5, 15, NULL),
    (5, 16, NULL),
    (4, 19, NULL),
    (3, 21, NULL);

INSERT INTO tournament (place, number_of_points, tournament_stage) VALUES
    (NULL, NULL, 'final'),
    (NULL, NULL, 'Round of 2'),
    (NULL, NULL, 'Round of 4'),
    (NULL, NULL, 'Round of 8'),
    (NULL, NULL, 'Round of 16');


INSERT INTO match (home_team_id, away_team_id, tournament_id, match_date, score, name_of_tournament) VALUES
    (1, 2, 1, '2023-04-01', '3:1', 'Russian Premier League'),
    (3, 1, 2, '2023-04-08', '1:1', 'Russian Premier League'),
    (1, 4, 3, '2023-04-15', '2:0', 'Russian Premier League'),
    (2, 1, 4, '2023-04-22', NULL, 'Russian Premier League'),
    (1, 3, 5, '2023-04-29', NULL, 'Russian Premier League'),
    (2, 5, 6, '2023-05-07', '2:2', 'Champions League'),
    (5, 4, 7, '2023-05-10', '1:3', 'Champions League'),
    (7, 6, 8, '2023-05-17', '2:2', 'Champions League'),
    (7, 8, 9, '2023-05-21', '1:1', 'Russian Premier League'),
    (2, 1, 10, '2023-04-22', '2:3', 'Russian Premier League'),
    (1, 3, 11, '2023-04-29', '4:2', 'Russian Premier League'),
    (2, 5, 12, '2023-05-07', '2:2', 'Champions League'),
    (5, 4, 13, '2023-05-10', '1:3', 'Champions League'),
    (7, 6, 14, '2023-05-17', '2:2', 'Champions League'),
    (7, 8, 15, '2023-05-21', '2:5', 'Russian Premier League');

INSERT INTO match (home_team_id, away_team_id, tournament_id, match_date, score, name_of_tournament) VALUES
    (1, 2, 18, '2023-04-01', '3:1', 'Champions League'),
    (3, 1, 17, '2023-04-08', '1:1', 'Champions League'),
    (1, 4, 16, '2023-04-15', '2:0', 'Champions League'),
    (2, 1, 15, '2023-04-22', '5:0', 'Champions League'),
    (7, 3, 18, '2023-04-29','2:5', 'Champions League'),
    (2, 5, 18, '2023-05-07', '2:2', 'Champions League');

select * from clubs;
select * from Zenit_players;
select * from tournament;
select * from match;
select * from match_participation;
select * from match_news;

INSERT INTO match_participation (player_id, match_id, number_of_game_minutes, number_of_goals, number_of_assistants, having_a_red_card, having_a_yellow_card) VALUES
        (1, 1, 90, 0, 0, false, true),
        (1, 2, 45, 0, 0, false, false),
        (1, 3, 90, 0, 1, false, false),
        (3, 1, 90, 0, 0, true, false),
        (3, 2, 90, 1, 0, false, false),
        (4, 1, 90, 1, 0, false, false),
        (4, 3, 90, 0, 0, false, true),
        (2, 2, 90, 0, 1, false, false),
        (9, 1, 45, 0, 0, true, false),
        (10, 1, 45, 0, 0, false, false);

INSERT INTO match_news (match_id, comment)
VALUES
        (1, 'Отличный выступление Зенит в их победе над Уралом'),
        (2, 'Зенит не смогли обеспечить себе победу над Нижним Новгородом'),
        (3, 'Зенит доминировали над Крыльями Советов в их победе'),
        (4, 'Зенит обеспечили комфортную победу над Уралом'),
        (5, 'Зенит столкнулись с сильным противостоянием со стороны Нижнего Новгорода, и матч закончился вничью'),
        (6, 'Зенит провели жесткий бой против Реала в Лиге Чемпионов, но смогли добыть ничью'),
        (7, 'Зенит потерпели поражение от Клуб Америка в Лиге Чемпионов'),
        (8, 'Зенит одержали победу над Манчестер Юнайтед в Лиге Чемпионов'),
        (9, 'Зенит столкнулись с трудным вызовом против Зенита в последнем матче сезона');
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'Яутше_players';

SELECT match_id, home_team.club_name, away_team.club_name, match_date, score, name_of_tournament
FROM match
JOIN tournament ON match.tournament_id = tournament.tournament_id
JOIN clubs AS home_team ON match.home_team_id = home_team.club_id
JOIN clubs AS away_team ON match.away_team_id = away_team.club_id
where match_id = 10;

SELECT match_id, home_team.club_name, away_team.club_name, match_date, score, name_of_tournament
FROM match
JOIN tournament ON match.tournament_id = tournament.tournament_id
JOIN clubs AS home_team ON match.home_team_id = home_team.club_id
JOIN clubs AS away_team ON match.away_team_id = away_team.club_id
WHERE match.tournament_id = 1;


select * from match
JOIN tournament ON match.tournament_id = tournament.tournament_id
where match.tournament_id = 27;

SELECT home_team.club_name, away_team.club_name, match_date, score, name_of_tournament
FROM match
JOIN tournament ON match.tournament_id = tournament.tournament_id
JOIN clubs AS home_team ON match.home_team_id = home_team.club_id
JOIN clubs AS away_team ON match.away_team_id = away_team.club_id
WHERE match.tournament_id =27;

SELECT distinct name_of_tournament FROM match;
select club_name from clubs;

SELECT distinct name_of_tournament FROM match;

select name_of_tournament from match where name_of_tournament = 'Champions League';

select name_of_tournament from match where name_of_tournament = 'Russian Premier League';

select first_name, last_name, match_date, number_of_game_minutes, number_of_goals,number_of_assistants,having_a_red_card,having_a_yellow_card
from Zenit_players
JOIN match_participation ON (Zenit_players.player_id = match_participation.player_id)
JOIN match ON (match_participation.match_id = match.match_id)
where last_name = 'Малафеев';

SELECT first_name, last_name, match_date, number_of_game_minutes, number_of_goals, number_of_assistants, having_a_red_card, having_a_yellow_card
FROM Zenit_players
JOIN match_participation ON (Zenit_players.player_id = match_participation.player_id)
JOIN match ON (match_participation.match_id = match.match_id)
WHERE last_name LIKE 'е';