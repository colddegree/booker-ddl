drop database if exists booker;
create database booker character set utf8mb4 collate utf8mb4_unicode_ci;
use booker;

# TODO: добавить хранение соглашения с версионностью и соглашение с правилами гостиницы в заказ

create table locality ( # местоположение
  id serial,
  name varchar(255) not null
);

create table user ( # пользователь
  id serial,
  type tinyint unsigned not null, # 1 - менеджер, 2 - клиент
  login varchar(255) not null, # TODO: добавить уникальность поля login
  hashed_password varchar(255) not null,
  name varchar(255) not null,
  phone_number varchar(255),
  email_address varchar(255)
);

create table user_manager ( # менеджер
  id serial,
  user_id bigint unsigned not null,
  foreign key (user_id) references user(id)
);

create table user_customer ( # клиент
  id serial,
  user_id bigint unsigned not null,
  foreign key (user_id) references user(id)
);

create table hotel ( # гостиница
  id serial,
  name varchar(255) not null,
  description text,
  locality_id bigint unsigned not null,
  stars_count tinyint unsigned not null default 0,
  address varchar(255) not null unique,
  phone_number varchar(255) not null,
  email_address varchar(255) not null,
  manager_id bigint unsigned not null unique,
  foreign key (locality_id) references locality(id),
  foreign key (manager_id) references user_manager(id)
);

create table hotel_attraction ( # важное место (достопримечательность)
  id serial,
  name varchar(255) not null,
  hotel_id bigint unsigned not null,
  foreign key (hotel_id) references hotel(id)
);

create table hotel_rule ( # правило гостиницы
  id serial,
  hotel_id bigint unsigned not null,
  text text not null,
  created_at timestamp not null default current_timestamp,
  foreign key (hotel_id) references hotel(id)
);

create table hotel_room_type ( # тип номера
  id serial,
  hotel_id bigint unsigned not null,
  name varchar(255) not null,
  price int unsigned not null, # цена в день (в рублях)
  rooms_count int unsigned not null,
  available_rooms_count int unsigned not null,
  foreign key (hotel_id) references hotel(id)
);

create table hotel_room_type_discount ( # процент скидки на тип номера на определённую дату
  room_type_id bigint unsigned not null,
  `date` date not null,
  percentage tinyint unsigned not null,
  primary key (room_type_id, `date`),
  foreign key (room_type_id) references hotel_room_type(id)
);

create table room ( # гостиничный номер
  id serial,
  room_type_id bigint unsigned not null,
  foreign key (room_type_id) references hotel_room_type(id)
);

create table room_status ( # статус гостиничного номера на конкретную дату
  room_id bigint unsigned not null,
  `date` date not null,
  status tinyint unsigned,
  primary key (room_id, `date`),
  foreign key (room_id) references room(id)
);

create table facility ( # удобство
  id serial,
  name varchar(255) not null
);

create table bed ( # спальное место
  id serial,
  type tinyint unsigned not null, # 1 - взрослое, 2 - детское
  name varchar(255) not null,
  adults_max_capacity tinyint unsigned not null,
  kids_max_capacity tinyint unsigned not null
);

create table photo ( # фото
  id serial,
  url varchar(255) not null
);

create table hotel_photo_bind ( # фотография гостиницы
  hotel_id bigint unsigned not null,
  photo_id bigint unsigned not null,
  position tinyint unsigned not null,
  is_main bool not null default false,
  foreign key (hotel_id) references hotel(id),
  foreign key (photo_id) references photo(id),
  primary key (hotel_id, photo_id)
);

# TODO: разобраться
create table payment_status ( # статус оплаты
  id serial,
  status tinyint unsigned,
  total_price_in_rubles int unsigned not null,
  paid_rubles int unsigned not null default 0
);

# TODO: допилить статус оплаты и прочее с оплатой
create table hotel_order ( # заказ на бронирование номера
  id serial,
  customer_id bigint unsigned not null,
  room_type_id bigint unsigned not null,
  check_in_date date not null,
  check_out_date date not null,
  adults_count tinyint unsigned not null,
  kids_count tinyint unsigned not null default 0,
  comment varchar(255),
  payment_status_id bigint unsigned not null,
  created_at timestamp not null default current_timestamp,
  foreign key (customer_id) references user_customer(id),
  foreign key (room_type_id) references hotel_room_type(id),
  foreign key (payment_status_id) references payment_status(id)
);

create table hotel_order_room ( # индекс фактического гостиничного номера заказа
  id serial,
  order_id bigint unsigned not null,
  room varchar(255) not null,
  foreign key (order_id) references hotel_order (id)
);

# TODO: разобраться
create table payment_log ( # журнал операций оплат
  id serial,
  order_id bigint unsigned not null,
  amount_in_rubles int unsigned not null,
  created_at timestamp not null default current_timestamp,
  foreign key (order_id) references hotel_order (id)
);

create table payment_type ( # способ оплаты
  id serial,
  name varchar(255)
);
insert into payment_type (name) values ('Сбербанк Онлайн'), ('Яндекс.Деньги');

create table hotel_payment_type_bind ( # способ оплаты гостиницы
  hotel_id bigint unsigned not null,
  payment_type_id bigint unsigned not null,
  foreign key (hotel_id) references hotel(id),
  foreign key (payment_type_id) references payment_type(id),
  primary key (hotel_id, payment_type_id)
);

create table hotel_room_type_bed_bind ( # тип кровати у типа номера
  room_type_id bigint unsigned not null,
  bed_id bigint unsigned not null,
  foreign key (room_type_id) references hotel_room_type(id),
  foreign key (bed_id) references bed(id),
  primary key (room_type_id, bed_id)
);

create table hotel_room_type_facility_bind ( # удобство у типа номера
  room_type_id bigint unsigned not null,
  facility_id bigint unsigned not null,
  foreign key (room_type_id) references hotel_room_type(id),
  foreign key (facility_id) references facility(id),
  primary key (room_type_id, facility_id)
);

create table hotel_review ( # отзыв об отеле
  id serial,
  order_id bigint unsigned not null unique,
  summary_text text not null,
  advantages_text text not null,
  disadvantages_text text not null,
  created_at timestamp not null default current_timestamp,
  foreign key (order_id) references hotel_order (id)
);

create table hotel_review_feature ( # характеристка отзыва об отеле
  id serial,
  name varchar(255) not null
);
insert into hotel_review_feature (name) values ('Удобства'), ('Персонал'), ('Расположение'), ('Чистота'), ('Комфорт');

create table hotel_review_feature_rating ( # оценка характеристики отзыва об отеле
  id serial,
  review_id bigint unsigned not null,
  feature_id bigint unsigned not null,
  rating tinyint unsigned not null,
  foreign key (review_id) references hotel_review(id),
  foreign key (feature_id) references hotel_review_feature(id)
);
