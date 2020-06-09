drop database if exists booker;
create database booker character set utf8mb4 collate utf8mb4_unicode_ci;
use booker;

create table region ( # регион
  region_id int unsigned not null primary key,
  name varchar(255) not null
);

create table city ( # город
  id int unsigned not null primary key,
  region_id int unsigned not null,
  name varchar(255) not null,
  foreign key (region_id) references region (region_id)
);

create table user ( # пользователь
  id serial,
  type tinyint unsigned not null, # 1 - менеджер, 2 - клиент
  login varchar(255) not null unique,
  hashed_password varchar(255) not null,
  name varchar(255) not null,
  phone_number varchar(255) not null,
  email_address varchar(255) not null
);

create table hotel ( # гостиница
  id serial,
  name varchar(255) not null,
  description text,
  region_id int unsigned not null,
  city_id int unsigned,
  stars_count tinyint unsigned not null default 0,
  address varchar(255) not null unique,
  phone_number varchar(255) not null,
  email_address varchar(255) not null,
  manager_id bigint unsigned not null unique,
  foreign key (region_id) references region (region_id),
  foreign key (city_id) references city (id),
  foreign key (manager_id) references user (id)
);

create table hotel_attraction ( # важное место (достопримечательность)
  id serial,
  hotel_id bigint unsigned not null,
  name varchar(255) not null,
  foreign key (hotel_id) references hotel (id)
);

create table hotel_rule ( # правило гостиницы
  id serial,
  hotel_id bigint unsigned not null,
  text text not null,
  created_at timestamp not null default current_timestamp,
  foreign key (hotel_id) references hotel (id)
);

create table hotel_room_type ( # тип номера
  id serial,
  hotel_id bigint unsigned not null,
  name varchar(255) not null,
  price int unsigned not null, # цена в день (в рублях)
  rooms_count int unsigned not null,
  available_rooms_count int unsigned not null,
  foreign key (hotel_id) references hotel (id)
);

create table hotel_room_type_discount ( # процент скидки на тип номера на определённую дату
  room_type_id bigint unsigned not null,
  `date` date not null,
  percentage tinyint unsigned not null,
  primary key (room_type_id, `date`),
  foreign key (room_type_id) references hotel_room_type (id)
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
  kids_max_capacity tinyint unsigned not null,
  hotel_id bigint unsigned, # для того, чтобы можно было менеджеру добавить кастомные спальные места
  foreign key (hotel_id) references hotel (id)
);

# TODO: понять, что тут должно быть вместо урла (может имя файла + путь до него)
create table photo ( # фото
  id serial,
  url varchar(255) not null
);

create table hotel_photo_bind ( # фотография гостиницы
  hotel_id bigint unsigned not null,
  photo_id bigint unsigned not null,
  position tinyint unsigned not null,
  is_main bool not null default false,
  foreign key (hotel_id) references hotel (id),
  foreign key (photo_id) references photo (id),
  primary key (hotel_id, photo_id)
);

create table hotel_order ( # заказ на бронирование номера
  id serial,
  hotel_id bigint unsigned not null,
  customer_id bigint unsigned not null,
  check_in_date date not null,
  check_out_date date not null,
  adults_count tinyint unsigned not null,
  kids_count tinyint unsigned not null default 0,
  comment varchar(255),
  cost int unsigned not null, # стоимость заказа (в рублях)
  created_at timestamp not null default current_timestamp,
  foreign key (hotel_id) references hotel (id),
  foreign key (customer_id) references user (id)
);

create table hotel_order_room ( # индекс фактического гостиничного номера заказа
  id serial,
  order_id bigint unsigned not null,
  room_type_id bigint unsigned not null,
  room varchar(255), # nullable т.к. проставляется менеджером после заселения
  foreign key (order_id) references hotel_order (id),
  foreign key (room_type_id) references hotel_room_type (id)
);

create table hotel_order_payment ( # оплата заказа
  id serial,
  order_id bigint unsigned not null,
  amount int unsigned not null, # сколько оплачено (в рублях)
  created_at timestamp not null default current_timestamp,
  foreign key (order_id) references hotel_order (id)
);

create table payment_type ( # способ оплаты
  id serial,
  name varchar(255)
);
insert into payment_type (id, name) values (1, 'Оплата на месте'), (2, 'Предоплата');

create table hotel_payment_type ( # способ оплаты гостиницы
  hotel_id bigint unsigned not null,
  payment_type_id bigint unsigned not null,
  foreign key (hotel_id) references hotel(id),
  foreign key (payment_type_id) references payment_type (id),
  primary key (hotel_id, payment_type_id)
);

create table hotel_room_type_bed ( # тип кровати у типа номера
  room_type_id bigint unsigned not null,
  bed_id bigint unsigned not null,
  foreign key (room_type_id) references hotel_room_type (id),
  foreign key (bed_id) references bed (id),
  primary key (room_type_id, bed_id)
);

create table hotel_room_type_facility ( # удобство у типа номера
  room_type_id bigint unsigned not null,
  facility_id bigint unsigned not null,
  foreign key (room_type_id) references hotel_room_type (id),
  foreign key (facility_id) references facility (id),
  primary key (room_type_id, facility_id)
);

create table hotel_review ( # отзыв о гостинице
  id serial,
  order_id bigint unsigned not null unique,
  summary_text text not null,
  advantages_text text not null,
  disadvantages_text text not null,
  created_at timestamp not null default current_timestamp,
  foreign key (order_id) references hotel_order (id)
);

create table hotel_review_feature ( # характеристка отзыва о гостинице
  id serial,
  name varchar(255) not null
);
insert into hotel_review_feature (id, name) values (1, 'Удобства'), (2, 'Персонал'), (3, 'Расположение'), (4, 'Чистота'), (5, 'Комфорт');

create table hotel_review_feature_rating ( # оценка характеристики отзыва о гостинице
  id serial,
  review_id bigint unsigned not null,
  feature_id bigint unsigned not null,
  rating tinyint unsigned not null,
  foreign key (review_id) references hotel_review (id),
  foreign key (feature_id) references hotel_review_feature (id)
);

create table complaint ( # жалоба клиента на гостиницу
  id serial,
  customer_id bigint unsigned not null,
  hotel_id bigint unsigned not null,
  text text not null,
  created_at timestamp not null default current_timestamp,
  foreign key (customer_id) references user (id),
  foreign key (hotel_id) references hotel (id)
);


# TODO: услуги + фоточки для услуг


