-- создаём таблицу note (если нет)
create table if not exists note (
  id   bigserial primary key,
  text varchar(255)
);

-- пример стартовых данных
insert into note(text) values ('first note via flyway') on conflict do nothing;
